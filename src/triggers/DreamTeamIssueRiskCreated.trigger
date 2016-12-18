trigger DreamTeamIssueRiskCreated on BLND_DFDT_Issue__c (after insert) {
    List<String> chatterStrings = new List<String>();
    List<String> chatterLinkUrls = new List<String>();
    List<String> chatterLinkTitles = new List<String>();
    List<String> toAddresses = new List<String>();
    Id projectId, taskId, userId, ownerId;
    String projectName, taskName, userName, userEmail, ownerEmail;
    String emailSubject, emailTextBody, emailHtmlBody, chatterBody;
    
    try {
        // get project names, task names, and owner emails
        Set<id> projectIds = new Set<id>();
        Set<id> taskIds = new Set<id>();
        Set<id> userIds = new Set<id>();
        for (BLND_DFDT_Issue__c t : Trigger.new) {
            projectId = t.BLND_Project_Link__c;
            if (projectId != NULL) {
                projectIds.add(projectId);
            }
            taskId = t.BLND_Task_Link__c;
            if (taskId != NULL) {
                taskIds.add(taskId);
            }
            userId = t.BLND_Issue_Owner__c;
            if (userId != NULL) {
                userIds.add(userId);
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
        
        emailSubject = 'DreamTeam Issues/Risks Created';
        emailTextBody = 'The following DreamTeam issues/risks have been created.\r\n\r\n';
        emailHtmlBody = 'The following DreamTeam issues/risks have been created.\r\n\r\n';
        for(BLND_DFDT_Issue__c t: Trigger.new) {
            // project name
            projectName = '';
            projectId = t.BLND_Project_Link__c;
            BLND_DFDT_Project__c oneproject = projects.get(projectId);
            if (oneproject != NULL) {
                projectName = oneproject.name;
            }
            // task name
            taskName = '';
            taskId = t.BLND_Task_Link__c;
            BLND_DFDT_Task__c onetask = tasks.get(taskId);
            if (onetask != NULL) {
                taskName = onetask.name;
            }
            // user name and email
            userName = 'None';
            userEmail = '';
            userId = t.BLND_Issue_Owner__c;
            User oneuser = users.get(userId);
            if (oneuser != NULL) {
                userName = oneuser.name;
                userEmail = oneuser.Email;
            }
            if (userEmail != '') {
                toAddresses.add(userEmail);
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
            emailTextBody += t.BLND_Type__c + ' Name: ' + t.name + '\r\n';
            if (emailUrl != '' && DreamTeamTriggerUtil.dtEmailLinkType == 'Project Calendar') {
                emailHtmlBody += t.BLND_Type__c + ' Name: ' + '<a href=\'' + emailUrl + DreamTeamTriggerUtil.GetIdParams(projectId, taskId, t.Id) + '\'>' + t.name + '</a>'+ '\r\n';
            }
            else {
            	emailHtmlBody += t.BLND_Type__c + ' Name: ' + t.name + '\r\n';
            }
            chatterBody += t.BLND_Type__c + ' Name: ' + t.name + '\r\n';
           	emailTextBody += t.BLND_Type__c + ' Owner: ' + userName + '\r\n';
           	emailHtmlBody += t.BLND_Type__c + ' Owner: ' + userName + '\r\n';
           	chatterBody += t.BLND_Type__c + ' Owner: ' + userName + '\r\n';
			emailTextBody += t.BLND_Type__c + ' Status: ' + t.BLND_Status__c + '\r\n';
           	emailHtmlBody += t.BLND_Type__c + ' Status: ' + t.BLND_Status__c + '\r\n';
           	chatterBody += t.BLND_Type__c + ' Status: ' + t.BLND_Status__c + '\r\n';
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
			chatterStrings.add('created a DreamTeam ' + t.BLND_Type__c + '.\r\n\r\n' + chatterBody);
   			chatterLinkUrls.add(chatterUrl);
   			chatterLinkTitles.add(chatterTitle);
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