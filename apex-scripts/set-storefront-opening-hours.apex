// Define the days of the week
List<String> DAYS = new List<String>{
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
};

// Get all storefronts
List<Storefront__c> storefronts = [
    SELECT Id
    FROM Storefront__c
];
if (storefronts.isEmpty()) {
    System.debug(LoggingLevel.WARN, 'Aborting execution as no Storefronts were found.');
    return;
}

// Clear all existing hours of operation
delete [SELECT Id FROM Storefront_Hours_of_Operation__c];

// Prepare new hours of operation
List<Storefront_Hours_of_Operation__c> hoursToInsert = new List<Storefront_Hours_of_Operation__c>();
for (Storefront__c sf : storefronts) {
    for (String day : DAYS) {

        String openingTime = '09:00';
        String closingTime = '21:00';
        if (day == 'Saturday' || day == 'Sunday') {
            openingTime = '10:00';
            closingTime = '15:00';
        }

        hoursToInsert.add(
            new Storefront_Hours_of_Operation__c(
                Storefront__c = sf.Id,
                Day_of_Week__c = day,
                Opening_Time__c = openingTime,
                Closing_Time__c = closingTime
            )
        );
    }
}

// Save opening hours
insert hoursToInsert;
System.debug(
    LoggingLevel.INFO,
    'Inserted ' +
        hoursToInsert.size() +
        ' operating hour rows across ' +
        storefronts.size() +
        ' storefront(s).'
);