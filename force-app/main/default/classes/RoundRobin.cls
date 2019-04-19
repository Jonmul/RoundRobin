/*
Created by: Jonathan Muller
Date: 2019-03-08

This class handles all of the core RoundRobin functionality, and is built to support any SFDC Object with an Owner field.

*/
public class RoundRobin {
    
    /****** New Round-Robin Functionality  ******/
    public static void roundRobin(List<SObject> newItems){
        
        // Build map of the OwnerId Queues to the List of SObject Records that belong to each QueueId
        Map<Id,List<SObject>> queueToSObjectListMap = getQueueToSObjectListMap(newItems);
        
        // Build a map of Assignment Groups to the List of SObject Records that belong to each Assignment Group
        Map<Id,List<SObject>> groupSObjectMap = getGroupSObjectMap(queueToSObjectListMap);
        
        // Build map of Assignment Group to the List of Assignment_Groups__c, which is essentially the list of Users in each group
        // Object names are confusing, but the short of it is group Id mapped to the list of Users in each group
        Map<Id,List<Assignment_Groups__c>> groupMap = getGroupMap(groupSObjectMap.keySet());
        
        // List to update Assignment Groups for standard Round-Robin
        List<Assignment_Groups__c> updateAG = new List<Assignment_Groups__c>();
        
        // for each master Assignment_Group_Name__c record, iterate over the list of SObjects that apply to that record
        for(Id assignmentGroup: groupMap.keySet()){
            List<SObject> sObjectsToProcess = groupSObjectMap.get(assignmentGroup);
            List<Assignment_Groups__c> userList = groupMap.get(assignmentGroup);
            
            Integer index = 0;
            Long lastDateTime;
            for(SObject so:sObjectsToProcess){
                Integer userIndex = Math.mod(index,userList.size());
                Assignment_Groups__c assignedUser = userList[userIndex];
                
                so.put('OwnerId',assignedUser.User__c);  
                
                String assignmentLookup = getGroupRelationshipFieldName(so);
                if(assignmentLookup!=null) so.put(assignmentLookup,assignmentGroup);
                if(assignedUser.Target_Field__c !=null && hasSObjectField(assignedUser.Target_Field__c,so)){
                    so.put(assignedUser.Target_Field__c,assignedUser.Target_Field_Text__c);
                }
                
                //c.TempOwnerId__c = ag.User__c; 
                
                //Set last assignment datetime
                
                Long newDateTime = DateTime.now().getTime();
                while(newDateTime == lastDateTime){
                    newDateTime = DateTime.now().getTime();
                }
                DateTime theTime = DateTime.newInstance(newDateTime);
                assignedUser.Last_Assignment__c = theTime;
                assignedUser.Millisecond__c = theTime.millisecondGMT();
                
                if(!updateAG.contains(assignedUser)) updateAG.add(assignedUser);
                newDateTime = lastDateTime;
                index++;
            }
        }
        if (updateAG.size()>0) {
            update updateAG;
        }
    }
    
    
    // FINISHED
    private static Map<Id,List<Assignment_Groups__c>> getGroupMap(Set<Id> assignmentGroupIds){
        Map<Id,List<Assignment_Groups__c>> groupMap = new Map<Id,List<Assignment_Groups__c>>();
        
        for(Assignment_Groups__c ags : [SELECT Group_Name__c, User__c, Last_Assignment__c, Millisecond__c, Target_Field__c, Target_Field_Text__c
                                        FROM Assignment_Groups__c 
                                        WHERE Group_Name__c in :assignmentGroupIds 
                                        AND Active__c = 'True' AND User_Active__c = 'True'
                                        ORDER BY Last_Assignment__c, Millisecond__c])
        {
            if(groupMap.containsKey(ags.Group_Name__c)){
                groupMap.get(ags.Group_Name__c).add(ags);
            }else{
                List<Assignment_Groups__c> tempAGList = new List<Assignment_Groups__c>();
                tempAGList.add(ags);
                groupMap.put(ags.Group_Name__c,tempAGList);
            }
        }
        return groupMap;
    }
    
    // FINISHED
    private static Map<Id,List<SObject>> getGroupSObjectMap(Map<Id,List<SObject>> queueToSObjectListMap){
        Map<Id,List<SObject>> groupSObjectMap = new Map<Id,List<SObject>>();
        
        List<Assignment_Group_Queues__c> assignmentQueues = [SELECT Assignment_Group_Name__c, QueueId__c 
                                                             FROM Assignment_Group_Queues__c WHERE QueueId__c in :queueToSObjectListMap.keySet() AND Active__c = 'True'];
        for(Assignment_Group_Queues__c agq : assignmentQueues){
            Id agn = agq.Assignment_Group_Name__c;
            if(groupSObjectMap.containsKey(agn)){
                groupSObjectMap.get(agn).addAll(queueToSObjectListMap.get(agq.QueueId__c));
            }else{
                List<SObject> tempSObjectList = new List<SObject>();
                tempSObjectList.addAll(queueToSObjectListMap.get(agq.QueueId__c));
                groupSObjectMap.put(agn,tempSObjectList);
            }
        }
        return groupSObjectMap;
    }
    
    // FINISHED
    private static Map<Id,List<SObject>> getQueueToSObjectListMap(List<SObject> newItems){
        // Map<QueueId,List<Affected SObject>>
        Map<Id,List<SObject>> queueToSObjectListMap = new Map<Id,List<SObject>>();
        List<SObject> affectedSObject = new List<SObject>();
        
        for(SObject item: newItems){
            Id ownerId = Id.valueOf(String.valueOf(item.get('OwnerId')));
            
            String ownerType = ownerId.getSObjectType().getDescribe().getName();
            //if(ownerType == 'Group'){
                affectedSObject.add(item);
                //queueIds.add(ownerId);
                if(queueToSObjectListMap.containsKey(ownerId)){
                    queueToSObjectListMap.get(ownerId).add(item);
                }else{
                    List<SObject> tempSObjectList = new List<SObject>();
                    tempSObjectList.add(item);
                    queueToSObjectListMap.put(ownerId,tempSObjectList);
                }
            //}
        }
        return queueToSObjectListMap;
    }
    
    private static boolean hasSObjectField(String fieldName, SObject so){
        return so.getSobjectType().getDescribe().fields.getMap().keySet().contains(fieldName.toLowerCase());
    }
    
    public static String getGroupRelationshipFieldName(SObject so){
        for(Schema.SobjectField strFld: so.getSobjectType().getDescribe().fields.getMap().Values()){
            if(strFld.getDescribe().getType() == Schema.DisplayType.REFERENCE)
            {
                //system.debug('==parent object='+strFld.getDescribe().getReferenceTo());
                String objectName = String.valueOf(strFld.getDescribe().getReferenceTo()[0]);
                if(objectName=='Assignment_Group_Name__c'){
                    return strFld.getDescribe().getName();
                }
            } 
        }
        return null;
    }
}