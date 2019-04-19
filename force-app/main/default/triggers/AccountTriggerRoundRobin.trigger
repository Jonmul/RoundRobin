/*
Created by: Jonathan Muller
Date: 2019-03-08

This is a sample basic Account Trigger, using an Apex framework for calling a corresponding Account Trigger Class. 
I've named this Trigger to be specific to the Round-Robin App, to prevent issues when installing into your SFDC Org.
You may consider consolidating the Round-Robin handling into your own Account Trigger.

*/
trigger AccountTriggerRoundRobin on Account (before insert, before update,after update,after insert) {
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            AccountTriggerRoundRobinClass.onBeforeInsert(Trigger.new);
        }else if(Trigger.isUpdate){
            AccountTriggerRoundRobinClass.onBeforeUpdate(Trigger.oldMap,Trigger.newMap);
        }
    }else if(Trigger.isAfter){
        if(Trigger.isInsert){
            AccountTriggerRoundRobinClass.onAfterInsert(Trigger.newMap);
        }else if(Trigger.isUpdate){
            AccountTriggerRoundRobinClass.onAfterUpdate(Trigger.oldMap,Trigger.newMap);
        }
    }
}