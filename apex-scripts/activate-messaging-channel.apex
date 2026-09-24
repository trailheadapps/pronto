MessagingChannel channel = [SELECT Id, IsActive FROM MessagingChannel WHERE DeveloperName='Customer_Service_Agent'];
channel.IsActive = true;
update channel;
