trigger DreamTeamActionItemUpdated on BLND_DFDT_Action_Item__c (after update) {
    List<String> chatterStrings = new List<String>();
    List<String> chatterLinkUrls = new List<String>();
    List<String> chatterLinkTitles = new List<String>();
    List<String> toAddresses = new List<String>();
    String projectName, taskName, issueName, issueType;
    Id projectId, taskId, issueId, oldUserId, newUserId, ownerId;
    String oldUserName, oldUserEmail, newUserName, newUserEmail, ownerEmail;
    String emailSubject, emailTextBody, emailHtmlBody, chatterBody;
    
    try {
        // get project names, task names, issue names, and owner emails
        Set<id> projectIds = new Set<id>();
        Set<id> taskIds = new Set<id>();
        Set<id> issueIds = new Set<id>();
        Set<id> userIds = new Set<id>();
        for (BLND_DFDT_Action_Item__c t : Trigger.new) {
            BLND_DFDT_Action_Item__c oldt = Trigger.oldMap.get(t.Id);
            projectId = t.BLND_Project_Link__c;
            if (projectId != NULL) {
                projectIds.add(projectId);
            }
            taskId = t.BLND_Task_Link__c;
            if (taskId != NULL) {
                taskIds.add(taskId);
            }
            issueId = t.BLND_Issue_Link__c;
            if (issueId != NULL) {
                issueIds.add(issueId);
            }
            newUserId = t.BLND_Action_Owner__c;
            if (newUserId != NULL) {
                userIds.add(newUserId);
            }
            oldUserId = oldt.BLND_Action_Owner__c;
            if (oldUserId != NULL) {
                userIds.add(oldUserId);
            }
        }
        
        // if action item assigned to issue, task id comes from issue not action item
        Map<id, BLND_DFDT_Issue__c> issues = new Map<id, BLND_DFDT_Issue__c>([Select Name,BLND_Type__c,BLND_Task_Link__c from BLND_DFDT_Issue__c Where Id in :issueIds]);
        for (Id id : issueIds) {
            taskId = issues.get(id).BLND_Task_Link__c;
            if (taskId != NULL) {
                taskIds.add(taskId);
            }
        }
        Map<id, BLND_DFDT_Project__c> projects = new Map<id, BLND_DFDT_Project__c>([Select Name,OwnerId from BLND_DFDT_Project__c Where Id in :projectIds]);
        Map<id, BLND_DFDT_Task__c> tasks = new Map<id, BLND_DFDT_Task__c>([Select Name from BLND_DFDT_Task__c Where Id in :taskIds]);
        Map<id, User> users = new Map<id, User>([Select Name,Email from User Where Id in :userIds]);
        
        // get unique project owner ids and emails
        Set<id> ownerIds = new Set<id>();
        for (Id id : projects.keySet()) {
            ownerId = projects.get(id).OwnerId;
            if (ownerId != NULL) {
                ownerIds.add(ownerId);
            }
        }
        Map<id, User> owners = new Map<id, User>([Select Email from User Where Id in :ownerIds]);
        
        emailSubject = 'DreamTeam Action Items Updated';
        emailTextBody = 'The following DreamTeam action items have been updated.\r\n\r\n';
        emailHtmlBody = 'The following DreamTeam action items have been updated.\r\n\r\n';
        for(BLND_DFDT_Action_Item__c t: Trigger.new) {
            BLND_DFDT_Action_Item__c oldt = Trigger.oldMap.get(t.Id);
            if ((oldt.name  != t.name) || (oldt.BLND_Action_Owner__c  != t.BLND_Action_Owner__c) || (oldt.BLND_Status__c  != t.BLND_Status__c)) {
                // project name
                projectName = '';
                projectId = t.BLND_Project_Link__c;
                BLND_DFDT_Project__c oneproject = projects.get(projectId);
                if (oneproject != NULL) {
                    projectName = oneproject.name;
                }
                // task name
                taskName = '';
                if (t.BLND_Issue_Link__c == NULL) {
                    taskId = t.BLND_Task_Link__c;
                }
                else {
                    taskId = issues.get(t.BLND_Issue_Link__c).BLND_Task_Link__c;
                }
                BLND_DFDT_Task__c onetask = tasks.get(taskId);
                if (onetask != NULL) {
                    taskName = onetask.name;
                }
                // issue name
                issueName = '';
                issueType = 'Issue';
                issueId = t.BLND_Issue_Link__c;
                BLND_DFDT_Issue__c oneissue = issues.get(issueId);
                if (oneissue != NULL) {
                    issueName = oneissue.name;
                    issueType = oneissue.BLND_Type__c;
                }
                // old user name and email
                oldUserName = 'None';
                oldUserEmail = '';
                oldUserId = oldt.BLND_Action_Owner__c;
                User oneuser = users.get(oldUserId);
                if (oneuser != NULL) {
                    oldUserName = oneuser.name;
                    oldUserEmail = oneuser.Email;
                }
                if (oldUserEmail != '') {
                    toAddresses.add(oldUserEmail);
                }
                // new user name and email
                newUserName = 'None';
                newUserEmail = '';
                newUserId = t.BLND_Action_Owner__c;
                oneuser = users.get(newUserId);
                if (oneuser != NULL) {
                    newUserName = oneuser.name;
                    newUserEmail = oneuser.Email;
                }
                if (newUserEmail != '') {
                    toAddresses.add(newUserEmail);
                }
                // project owner email
                ownerEmail = '';
                if (oneproject != NULL) {
                    ownerId = oneproject.OwnerId;
                    oneuser = owners.get(ownerId);
                    if (oneuser != NULL) {
                        ownerEmail = oneuser.Email;
                    }
                }
                if (ownerEmail != '') {
                    toAddresses.add(ownerEmail);
                }
                // construct message
	            chatterBody = '';
	            String projMgrUrl = DreamTeamTriggerUtil.GetTrackBackUrl(false);
	            String projCalUrl = DreamTeamTriggerUtil.GetTrackBackUrl(true);
	            String emailUrl = '';
	            if (DreamTeamTriggerUtil.dtEmailLinkType == 'Project Manager') {
					emailUrl = projMgrUrl;
				}
				else {
					if (DreamTeamTriggerUtil.dtEmailLinkType == 'Project Calendar') {
						emailUrl = projCalUrl;
					}
				}
	            if (projectId != NULL) {
	                emailTextBody += 'Project Name: ' + projectName + '\r\n';
	                if (emailUrl != '') {
	                    emailHtmlBody += 'Project Name: ' + '<a href=\'' + emailUrl + DreamTeamTriggerUtil.GetIdParams(projectId, NULL, NULL) + '\'>' + projectname + '</a>'+ '\r\n';
	                }
	                else {
	                     emailHtmlBody += 'Project Name: ' + projectName + '\r\n';
	                }
	                chatterBody += 'Project Name: ' + projectName + '\r\n';
	            }
	            if (taskId != NULL) {
	                emailTextBody += 'Task Name: ' + taskName + '\r\n';
	                if (emailUrl != '') {
	                    emailHtmlBody += 'Task Name: ' + '<a href=\'' + emailUrl + DreamTeamTriggerUtil.GetIdParams(projectId, taskId, NULL) + '\'>' + taskName + '</a>'+ '\r\n';
	                }
	                else {
	                     emailHtmlBody += 'Task Name: ' + taskName + '\r\n';
	                }
	                chatterBody += 'Task Name: ' + taskName + '\r\n';
	            }
	            if (issueId != NULL) {
	                emailTextBody += issueType + ' Name: ' + issueName + '\r\n';                
	                if (emailUrl != '' && DreamTeamTriggerUtil.dtEmailLinkType == 'Project Calendar') {
	                	emailHtmlBody += issueType + ' Name: ' + '<a href=\'' + emailUrl + DreamTeamTriggerUtil.GetIdParams(projectId, taskId, issueId) + '\'>' + issueName + '</a>'+ '\r\n';
	                }
	                else {
	                	emailHtmlBody += issueType + ' Name: ' + issueName + '\r\n';
	                }
	                chatterBody += issueType + ' Name: ' + issueName + '\r\n';
	            }
	            if (oldt.name != t.name) {
	                emailTextBody += 'Old Action Item Name: ' + oldt.name + '\r\n';
	                emailHtmlBody += 'Old Action Item Name: ' + oldt.name + '\r\n';
	                chatterBody += 'Old Action Item Name: ' + oldt.name + '\r\n';
	                emailTextBody += 'New Action Item Name: ' + t.name + '\r\n';
	                if (emailUrl != '' && DreamTeamTriggerUtil.dtEmailLinkType == 'Project Calendar') {
		      			emailHtmlBody += 'New Action Item Name: ' + '<a href=\'' + emailUrl + DreamTeamTriggerUtil.GetIdParams(projectId, taskId, t.Id) + '\'>' + t.name + '</a>'+ '\r\n';
		            }
		            else {
		            	emailHtmlBody += 'New Action Item Name: ' + t.name + '\r\n';
		            }
	                chatterBody += 'New Action Item Name: ' + t.name + '\r\n';
	            }
	            else {
	        		emailTextBody += 'Action Item Name: ' + t.name + '\r\n';
	        		if (emailUrl != '' && DreamTeamTriggerUtil.dtEmailLinkType == 'Project Calendar') {
		      			emailHtmlBody += 'Action Item Name: ' + '<a href=\'' + emailUrl + DreamTeamTriggerUtil.GetIdParams(projectId, taskId, t.Id) + '\'>' + t.name + '</a>'+ '\r\n';
		            }
		            else {
		            	emailHtmlBody += 'Action Item Name: ' + t.name + '\r\n';
		            }
	        		chatterBody += 'Action Item Name: ' + t.name + '\r\n';
	            }
	            if (oldt.BLND_Action_Owner__c != t.BLND_Action_Owner__c) {
	                emailTextBody += 'Old Action Item Owner: ' + oldUserName + '\r\n';
	                emailHtmlBody += 'Old Action Item Owner: ' + oldUserName + '\r\n';
	                chatterBody += 'Old Action Item Owner: ' + oldUserName + '\r\n';
	                emailTextBody += 'New Action Item Owner: ' + newUserName + '\r\n';
	                emailHtmlBody += 'New Action Item Owner: ' + newUserName + '\r\n';
	                chatterBody += 'New Action Item Owner: ' + newUserName + '\r\n';
	            }
	            else {
	        		emailTextBody += 'Action Item Owner: ' + newUserName + '\r\n';
	        		emailHtmlBody += 'Action Item Owner: ' + newUserName + '\r\n';
	        		chatterBody += 'Action Item Owner: ' + newUserName + '\r\n';
	            }
	            if (oldt.BLND_Status__c != t.BLND_Status__c) {
	                emailTextBody += 'Old Action Item Status: ' + oldt.BLND_Status__c + '\r\n';
	                emailHtmlBody += 'Old Action Item Status: ' + oldt.BLND_Status__c + '\r\n';
	                chatterBody += 'Old Action Item Status: ' + oldt.BLND_Status__c + '\r\n';
	                emailTextBody += 'New Action Item Status: ' + t.BLND_Status__c;
	                emailHtmlBody += 'New Action Item Status: ' + t.BLND_Status__c;
	                chatterBody += 'New Action Item Status: ' + t.BLND_Status__c;
	            }
	            else {
	        		emailTextBody += 'Action Item Status: ' + t.BLND_Status__c + '\r\n';
	        		emailHtmlBody += 'Action Item Status: ' + t.BLND_Status__c + '\r\n';
	        		chatterBody += 'Action Item Status: ' + t.BLND_Status__c + '\r\n';
	            }
	            emailTextBody += '\r\n';
	            emailHtmlBody += '\r\n';
	            chatterBody += '\r\n';
	            // chatter
				String chatterUrl = '';
				String chatterTitle = '';
				if (DreamTeamTriggerUtil.dtChatterLinkType == 'Project Manager') {
					chatterUrl = projMgrUrl + DreamTeamTriggerUtil.GetIdParams(projectId, taskId, t.Id);
					chatterTitle = 'Project Manager';
				}
				else {
					if (DreamTeamTriggerUtil.dtChatterLinkType == 'Project Calendar') {
						chatterUrl = projCalUrl + DreamTeamTriggerUtil.GetIdParams(projectId, taskId, t.Id);
						chatterTitle = 'Project Calendar';
					}
				}
				chatterStrings.add('updated a DreamTeam action item.\r\n\r\n' + chatterBody);
	   			chatterLinkUrls.add(chatterUrl);
	   			chatterLinkTitles.add(chatterTitle);
	        }
        }
        if (DreamTeamTriggerUtil.dtChatterEnabled) {
        	DreamTeamTriggerUtil.CreateChatterPosts(chatterStrings, chatterLinkUrls, chatterLinkTitles);
        }
        if (DreamTeamTriggerUtil.dtEmailEnabled) {
        	DreamTeamTriggerUtil.SendEmail(toAddresses, emailSubject, emailTextBody, emailHtmlBody);
        }
    } catch (Exception e) {
        System.debug('ERROR:' + e);
    }
}