public with sharing class AGQueueTriggerClass {
	public static void onBeforeUpdate(Map<id,Assignment_Group_Queues__c> oldItems, Map<id,Assignment_Group_Queues__c> newItems){
		validateQueues(changedQueues(newItems.values(),oldItems));
	}

	public static void onAfterUpdate(Map<id,Assignment_Group_Queues__c> oldItems, Map<id,Assignment_Group_Queues__c> newItems){
	}

	public static void onBeforeInsert(List<Assignment_Group_Queues__c> newItems){
		validateQueues(newItems);
	}

	public static void onAfterInsert(Map<id,Assignment_Group_Queues__c> newItems){
	}


	// validates the record and updates the QueueId to be accurate and 18-digit
	public static void validateQueues(List<Assignment_Group_Queues__c> items){
		List<String> queueNames = new List<String>();
		List<Assignment_Group_Queues__c> standardQueues = new List<Assignment_Group_Queues__c>();

		for(Assignment_Group_Queues__c item : items) {
			if(item.User_Queue__c != null) {
				item.QueueId__c = item.User_Queue__c;
			}else{
				queueNames.add(item.Name);
				standardQueues.add(item);
			}
		}

		Map<String,Id> groupMap = getGroupMap(queueNames);
		for(Assignment_Group_Queues__c agq : standardQueues) {
			if(groupMap.containsKey(agq.Name)) {
				agq.QueueId__c = groupMap.get(agq.Name);
			}else{
				//throw an error
				agq.Valid_Queue__c = false;
				agq.addError('Invalid Queue name: Queue name "' + agq.Name + '" cannot be found.');
			}
		}

	}

	private static List<Assignment_Group_Queues__c> changedQueues(List<Assignment_Group_Queues__c> items,Map<id,Assignment_Group_Queues__c> oldItems){
		List<Assignment_Group_Queues__c> changedRecords = new List<Assignment_Group_Queues__c>();
		for(Assignment_Group_Queues__c item :items) {
			if(item.Name !=oldItems.get(item.Id).Name || item.User_Queue__c !=oldItems.get(item.Id).User_Queue__c) {
				changedRecords.add(item);
			}
		}
		return changedRecords;
	}

	private static Map<String,Id> getGroupMap(List<String> queueNames){
		List<Group> groups = [select Id,Name,DeveloperName from Group where Type = 'Queue'and Name in :queueNames];
		Map<String,Id> groupMap = new Map<String,Id>();

		for(Group g:groups) {
			groupMap.put(g.Name,g.Id);
		}
		return groupMap;
	}
}
