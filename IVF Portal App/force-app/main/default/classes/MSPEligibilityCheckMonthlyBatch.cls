public class MSPEligibilityCheckMonthlyBatch implements Database.Batchable<SObject>, Database.AllowsCallouts,Schedulable {
	private Integer batchSize;

    public MSPEligibilityCheckMonthlyBatch(Integer size) {
        this.batchSize = size;
    }
	public static Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            //SELECT Id, Applicant1__c,Applicant1PersonalHealthNumber__c,Applicant1MSPStatus__c,Applicant2__c,Applicant2PersonalHealthNumber__c,Applicant2MSPStatus__c,Applicant1Patient__c,Patient1PersonalHealthNumber__c,Patient1MSPStatus__c,Applicant2Patient__c,Patient2PersonalHealthNumber__c,Patient3PersonalHealthNumber__c FROM Case WHERE Status = 'Approved'
			SELECT Id,FundingComplete__c,ParentId, Parent.Applicant1PersonalHealthNumber__c,Parent.Applicant1Date__c, Parent.Applicant1MSPStatus__c,Parent.Applicant2PersonalHealthNumber__c,Parent.Applicant2Date__c, Parent.Applicant2MSPStatus__c,Parent.Patient1PersonalHealthNumber__c,Parent.Patient1Date__c,Parent.Patient1MSPStatus__c, Parent.Patient2PersonalHealthNumber__c,Parent.Patient2Date__c,Parent.Patient2MSPStatus__c,Parent.Patient3PersonalHealthNumber__c,Parent.Patient3Date__c,Parent.Patient3MSPStatus__c FROM Case WHERE Parent.status='approved' and FundingComplete__c=false
		]);
    }
	public void execute(Database.BatchableContext bc, List<SObject> scope) {
		List<Case> updatedCases = new List<Case>();
		Map<String,String> MSPStatusMap=new Map<String,String>();
        Set<String> phnSet = new Set<String>();

        for (Case c : (List<Case>) scope) {
            if (c.Parent.Applicant1PersonalHealthNumber__c != null) {
                phnSet.add(c.Parent.Applicant1PersonalHealthNumber__c);
            }
            if (c.Parent.Applicant2PersonalHealthNumber__c != null) {
                phnSet.add(c.Parent.Applicant2PersonalHealthNumber__c);
            }
			if (c.Parent.Patient1PersonalHealthNumber__c != null) {
                phnSet.add(c.Parent.Patient1PersonalHealthNumber__c);
            }
			if (c.Parent.Patient2PersonalHealthNumber__c != null) {
                phnSet.add(c.Parent.Patient2PersonalHealthNumber__c);
            }
			if (c.Parent.Patient3PersonalHealthNumber__c != null) {
                phnSet.add(c.Parent.Patient3PersonalHealthNumber__c);
            }
        }


        for (String phn : phnSet) {

            try {
                if (!String.isBlank(phn)) {
                    String responseBody = LRAIntegrationHandler.callLRAAPI('', 'GET', '', phn);
                    if(responseBody != null && responseBody == 'MSP_ACTIVE'){
						MSPStatusMap.put(phn,'Enrolled');
					}
					else{
						MSPStatusMap.put(phn,'Not Enrolled');
					}
                }
            } catch (Exception e) {
                System.debug('Exception while Integration for MSP Check'+e.getmessage());
            }
        }

		for(case c : (List<Case>) scope)
		{
			Case updateCase =new case();
			updateCase.id=c.parentId;
			if(c.Parent.Applicant1PersonalHealthNumber__c!=null && MSPStatusMap.get(c.Parent.Applicant1PersonalHealthNumber__c)!=null){
				updateCase.Applicant1MSPStatus__c=MSPStatusMap.get(c.Parent.Applicant1PersonalHealthNumber__c);
				updateCase.Applicant1Date__c  = System.today();
				
			}
			if(c.Parent.Applicant2PersonalHealthNumber__c!=null && MSPStatusMap.get(c.Parent.Applicant2PersonalHealthNumber__c)!=null){
				updateCase.Applicant2MSPStatus__c=MSPStatusMap.get(c.Parent.Applicant2PersonalHealthNumber__c);
				updateCase.Applicant2Date__c = System.today();
				
			}
			if(c.Parent.Patient1PersonalHealthNumber__c!=null && MSPStatusMap.get(c.Parent.Patient1PersonalHealthNumber__c)!=null){
				updateCase.Patient1MSPStatus__c=MSPStatusMap.get(c.Parent.Patient1PersonalHealthNumber__c);
				updateCase.Patient1Date__c = System.today();
			}
			if(c.Parent.Patient2PersonalHealthNumber__c!=null && MSPStatusMap.get(c.Parent.Patient2PersonalHealthNumber__c)!=null){
				updateCase.Patient2MSPStatus__c=MSPStatusMap.get(c.Parent.Patient2PersonalHealthNumber__c);
				updateCase.Patient2Date__c = System.today();
			}
			if(c.Parent.Patient3PersonalHealthNumber__c!=null && MSPStatusMap.get(c.Parent.Patient3PersonalHealthNumber__c)!=null){
				updateCase.Patient3MSPStatus__c=MSPStatusMap.get(c.Parent.Patient3PersonalHealthNumber__c);
				updateCase.Patient3Date__c = System.today();
				
			}
			updatedCases.add(updateCase);
		}
		if(updatedCases!=null)
		{
			try{
				database.update(updatedCases,false);
			}
			catch(Exception e){
				System.debug('Excepiton while updating the case application MSP data'+e.getmessage());
			}
		}
    }

    public void finish(Database.BatchableContext bc) {
    }
	public void execute(SchedulableContext sc) {
        
        Database.executeBatch(new MSPEligibilityCheckMonthlyBatch(batchSize), batchSize);
    }
}