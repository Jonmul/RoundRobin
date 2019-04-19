/*
Created by: Jonathan Muller
Date: 2019-03-08

This is a sample basic Account Trigger Class, using an Apex framework to handle different class calls.
I've named and coded this Class to be specific to the Round-Robin App, to prevent issues when installing into your SFDC Org.
You may consider consolidating this Round-Robin handling into your own Account Class or Trigger - depending on your coding framework.

*/
public with sharing class AccountTriggerRoundRobinClass {
	public static void onBeforeUpdate(Map<id,Account> oldItems, Map<id,Account> newItems){
		RoundRobin.roundRobin(newItems.values());
	}

	public static void onAfterUpdate(Map<id,Account> oldItems, Map<id,Account> newItems){
	}

	public static void onBeforeInsert(List<Account> newItems){
		RoundRobin.roundRobin(newItems);
	}

	public static void onAfterInsert(Map<id,Account> newItems){
	}
}
