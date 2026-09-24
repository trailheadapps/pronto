// Delete records in reverse order to handle relationships (child to parent)
delete [SELECT id FROM Order_Item__c];
delete [SELECT id FROM Order__c];
delete [SELECT id FROM Review__c];
delete [SELECT id FROM Menu_Item__c];
delete [SELECT id FROM Menu__c];
delete [SELECT Id FROM Storefront_Hours_of_Operation__c];
delete [SELECT id FROM Storefront__c];
delete [SELECT id FROM Contact];
