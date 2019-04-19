trigger AGQueueTrigger on Assignment_Group_Queues__c (before insert, before update,after update,after insert) {
if(Trigger.isBefore){
        if(Trigger.isInsert){
            AGQueueTriggerClass.onBeforeInsert(Trigger.new);
        }else if(Trigger.isUpdate){
            AGQueueTriggerClass.onBeforeUpdate(Trigger.oldMap,Trigger.newMap);
        }
    }else if(Trigger.isAfter){
        if(Trigger.isInsert){
            AGQueueTriggerClass.onAfterInsert(Trigger.newMap);
        }else if(Trigger.isUpdate){
            AGQueueTriggerClass.onAfterUpdate(Trigger.oldMap,Trigger.newMap);
        }
    }
}