trigger DreamTeamTaskResourceChange on BLND_DFDT_Task__c (after update) {
    List<String> chatterStrings = new List<String>();
    List<String> chatterLinkUrls = new List<String>();
    List<String> chatterLinkTitles = new List<String>();
    List<String> toAddresses = new List<String>();
    Id projectId, contactId, userId, ownerId;
    String projectName, ownerEmail, oneItem;
    String emailSubject, emailTextBody, emailHtmlBody, chatterBody;
    
    try {
        // get unique project ids and names
        Set<id> projectIds = new Set<id>();
        for (BLND_DFDT_Task__c t : Trigger.new) {
            projectId = t.BLND_Project_Link__c;
            projectIds.add(projectId);
        }
        Map<id, BLND_DFDT_Project__c> projects = new Map<id, BLND_DFDT_Project__c>([Select Name,OwnerId from BLND_DFDT_Project__c Where Id in :projectIds]);
        
        // get unique project owner ids and emails
        Set<id> ownerIds = new Set<id>();
        for (Id id : projects.keySet()) {
            ownerId = projects.get(id).OwnerId;
            ownerIds.add(ownerId);
        }
        Map<id, User> owners = new Map<id, User>([Select Email from User Where Id in :ownerIds]);
        
        // get unique list of resource names for all tasks
        Set<String> uniqueNames = new Set<String>();
        for (BLND_DFDT_Task__c t : Trigger.new) {
            String names = t.BLND_Resources__c;
            names = DreamTeamTriggerUtil.CleanResources(names);
            List<String> l = names.split(',', 0);
            uniqueNames.addAll(l);
        }
        
        // get all resources with matching project and name
        Map<id, BLND_DFDT_Resource__c> resources = new Map<id, BLND_DFDT_Resource__c>([Select Name,BLND_Project_Link__c,BLND_Purpose__c,BLND_Attachment_Link__c from BLND_DFDT_Resource__c Where BLND_Project_Link__c in :projectIds and Name in :uniqueNames]);
        
        // get unique contact and user ids
        Set<id> contactIds = new Set<id>();
        Set<id> userIds = new Set<id>();
        for (Id id : resources.keySet()) {
            String purpose = resources.get(id).BLND_Purpose__c;
            if (purpose == 'Contact') {
                contactId = resources.get(id).BLND_Attachment_Link__c;
                contactIds.add(contactId);
            }
            else if (purpose == 'User') {
                userId = resources.get(id).BLND_Attachment_Link__c;
                userIds.add(userId);
            }
        }
        Map<id, Contact> contacts = new Map<id, Contact>([Select Email from Contact Where Id in :contactIds]);
        Map<id, User> users = new Map<id, User>([Select Email from User Where Id in :userIds]);
        
        emailSubject = 'DreamTeam Task Resources Changed';
        emailTextBody = 'The resources on the following DreamTeam tasks have been changed.\r\n\r\n';
        emailHtmlBody = 'The resources on the following DreamTeam tasks have been changed.\r\n\r\n';
        for(BLND_DFDT_Task__c t: Trigger.new) {
            BLND_DFDT_Task__c oldt = Trigger.oldMap.get(t.Id);
            String oldList = DreamTeamTriggerUtil.CleanResources(oldt.BLND_Resources__c);
            String newList = DreamTeamTriggerUtil.CleanResources(t.BLND_Resources__c);
            if (DreamTeamTriggerUtil.CompareResources(oldList, newList)) {
                oldList = oldList.replace(',', ', ');
                newList = newList.replace(',', ', ');
                // project name
                projectName = '';
                projectId = t.BLND_Project_Link__c;
                BLND_DFDT_Project__c oneproject = projects.get(projectId);
                if (oneproject != NULL) {
                    projectName = oneproject.name;
                }
                // project owner email
                ownerEmail = '';
                if (oneproject != NULL) {
                    ownerId = oneproject.OwnerId;
                    User oneuser = owners.get(ownerId);
                    if (oneuser != NULL) {
                        ownerEmail = oneuser.Email;
                    }
                }
                if (ownerEmail != '') {
                    toAddresses.add(ownerEmail);
                }
                // add task resource emails (contact or user)
                String names = t.BLND_Resources__c;
                names = DreamTeamTriggerUtil.CleanResources(names);
                List<String> namelist = names.split(',', 0);
                for (String s : namelist) {
                    oneItem = DreamTeamTriggerUtil.Resource2Email(projectId, s, resources, contacts, users);
                    if (oneItem != '') {
                        toAddresses.add(oneItem);
                    }
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
	            if (t.id != NULL) {
	                emailTextBody += 'Task Name: ' + t.name + '\r\n';
	                if (emailUrl != '') {
	                    emailHtmlBody += 'Task Name: ' + '<a href=\'' + emailUrl + DreamTeamTriggerUtil.GetIdParams(projectId, t.Id, NULL) + '\'>' + t.name + '</a>'+ '\r\n';
	                }
	                else {
	                     emailHtmlBody += 'Task Name: ' + t.name + '\r\n';
	                }
	                chatterBody += 'Task Name: ' + t.name + '\r\n';
	            }
	            emailTextBody += 'Old Resources: ' + oldList + '\r\n';
	            emailHtmlBody += 'Old Resources: ' + oldList + '\r\n';
	            chatterBody += 'Old Resources: ' + oldList + '\r\n';
	            emailTextBody += 'New Resources: ' + newList + '\r\n';
	            emailHtmlBody += 'New Resources: ' + newList + '\r\n';
	            chatterBody += 'New Resources: ' + newList + '\r\n';
	            emailTextBody += '\r\n';
	            emailHtmlBody += '\r\n';
	            chatterBody += '\r\n';
	            // chatter
				String chatterUrl = '';
				String chatterTitle = '';
				if (DreamTeamTriggerUtil.dtChatterLinkType == 'Project Manager') {
					chatterUrl = projMgrUrl + DreamTeamTriggerUtil.GetIdParams(projectId, t.Id, NULL);
					chatterTitle = 'Project Manager';
				}
				else {
					if (DreamTeamTriggerUtil.dtChatterLinkType == 'Project Calendar') {
						chatterUrl = projCalUrl + DreamTeamTriggerUtil.GetIdParams(projectId, t.Id, NULL);
						chatterTitle = 'Project Calendar';
					}
				}
				chatterStrings.add('added a DreamTeam project resource.\r\n\r\n' + chatterBody);
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