trigger DreamTeamHighlightCreated on BLND_DFDT_Highlight__c (after insert) {
    List<String> chatterStrings = new List<String>();
    List<String> chatterLinkUrls = new List<String>();
    List<String> chatterLinkTitles = new List<String>();
    List<String> toAddresses = new List<String>();
    Id projectId, ownerId;
    String projectName, ownerEmail;
    String emailSubject, emailTextBody, emailHtmlBody, chatterBody;
    
    try {
        // get unique project ids and names
        Set<id> projectIds = new Set<id>();
        for (BLND_DFDT_Highlight__c t : Trigger.new) {
            projectId = t.BLND_Project_Link__c;
            if (projectId != NULL) {
                projectIds.add(projectId);
            }
        }
        Map<id, BLND_DFDT_Project__c> projects = new Map<id, BLND_DFDT_Project__c>([Select Name,OwnerId from BLND_DFDT_Project__c Where Id in :projectIds]);
        
        // get unique project owner ids and emails
        Set<id> ownerIds = new Set<id>();
        for (Id id : projects.keySet()) {
            ownerId = projects.get(id).OwnerId;
            ownerIds.add(ownerId);
        }
        Map<id, User> owners = new Map<id, User>([Select Email from User Where Id in :ownerIds]);
        
        emailSubject = 'DreamTeam Highlights Created';
        emailTextBody = 'The following DreamTeam highlights have been created.\r\n\r\n';
        emailHtmlBody = 'The following DreamTeam highlights have been created.\r\n\r\n';
        for(BLND_DFDT_Highlight__c t: Trigger.new) {
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
            emailTextBody += 'Highlight Name: ' + t.name + '\r\n';
            if (emailUrl != '' && DreamTeamTriggerUtil.dtEmailLinkType == 'Project Calendar') {
      			emailHtmlBody += 'Highlight Name: ' + '<a href=\'' + emailUrl + DreamTeamTriggerUtil.GetIdParams(projectId, NULL, t.Id) + '\'>' + t.name + '</a>'+ '\r\n';
            }
            else {
            	emailHtmlBody += 'Highlight Name: ' + t.name + '\r\n';
            }
            chatterBody += 'Highlight Name: ' + t.name + '\r\n';
            emailTextBody += '\r\n';
            emailHtmlBody += '\r\n';
            chatterBody += '\r\n';
            // chatter
			String chatterUrl = '';
			String chatterTitle = '';
			if (DreamTeamTriggerUtil.dtChatterLinkType == 'Project Manager') {
				chatterUrl = projMgrUrl + DreamTeamTriggerUtil.GetIdParams(projectId, NULL, t.Id);
				chatterTitle = 'Project Manager';
			}
			else {
				if (DreamTeamTriggerUtil.dtChatterLinkType == 'Project Calendar') {
					chatterUrl = projCalUrl + DreamTeamTriggerUtil.GetIdParams(projectId, NULL, t.Id);
					chatterTitle = 'Project Calendar';
				}
			}
			chatterStrings.add('created a DreamTeam highlight.\r\n\r\n' + chatterBody);
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