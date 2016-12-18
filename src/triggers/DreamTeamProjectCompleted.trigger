trigger DreamTeamProjectCompleted on BLND_DFDT_Project__c (after update) {
    List<String> chatterStrings = new List<String>();
    List<String> chatterLinkUrls = new List<String>();
    List<String> chatterLinkTitles = new List<String>();
    List<String> toAddresses = new List<String>();
    Id ownerId;
    String ownerEmail;
    String emailSubject, emailTextBody, emailHtmlBody, chatterBody;
    
    try {
        // get unique project owner ids and emails
        Set<id> ownerIds = new Set<id>();
        for (BLND_DFDT_Project__c t : Trigger.new) {
            ownerId = t.OwnerId;
            ownerIds.add(ownerId);
        }
        Map<id, User> owners = new Map<id, User>([Select Email from User Where Id in :ownerIds]);
        
        emailSubject = 'DreamTeam Projects Completed';
        emailTextBody = 'The following DreamTeam projects have been completed.\r\n\r\n';
        emailHtmlBody = 'The following DreamTeam projects have been completed.\r\n\r\n';
        for(BLND_DFDT_Project__c t: Trigger.new) {
            BLND_DFDT_Project__c oldt = Trigger.oldMap.get(t.Id);
            if ((oldt.BLND_Complete__c < 100.0) && (t.BLND_Complete__c >= 100.0)) {
                // project owner email
                ownerEmail = '';
                ownerId = t.OwnerId;
                User oneuser = owners.get(ownerId);
                if (oneuser != NULL) {
                    ownerEmail = oneuser.Email;
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
	            if (t.Id != NULL) {
	                emailTextBody += 'Project Name: ' + t.name + '\r\n';
	                if (emailUrl != '') {
	                    emailHtmlBody += 'Project Name: ' + '<a href=\'' + emailUrl + DreamTeamTriggerUtil.GetIdParams(t.Id, NULL, NULL) + '\'>' + t.name + '</a>'+ '\r\n';
	                }
	                else {
	                     emailHtmlBody += 'Project Name: ' + t.name + '\r\n';
	                }
	                chatterBody += 'Project Name: ' + t.name + '\r\n';
	            }
	            emailTextBody += '\r\n';
	            emailHtmlBody += '\r\n';
	            chatterBody += '\r\n';
	            // chatter
				String chatterUrl = '';
				String chatterTitle = '';
				if (DreamTeamTriggerUtil.dtChatterLinkType == 'Project Manager') {
					chatterUrl = projMgrUrl + DreamTeamTriggerUtil.GetIdParams(t.Id, NULL, NULL);
					chatterTitle = 'Project Manager';
				}
				else {
					if (DreamTeamTriggerUtil.dtChatterLinkType == 'Project Calendar') {
						chatterUrl = projCalUrl + DreamTeamTriggerUtil.GetIdParams(t.Id, NULL, NULL);
						chatterTitle = 'Project Calendar';
					}
				}
				chatterStrings.add('completed a DreamTeam project.\r\n\r\n' + chatterBody);
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