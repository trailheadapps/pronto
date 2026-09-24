// Get all storefronts
List<Storefront__c> storefronts = [
    SELECT Thumbnail__c
    FROM Storefront__c
];
if (storefronts.isEmpty()) {
    System.debug(LoggingLevel.WARN, 'Aborting execution as no Storefronts were found.');
    return;
}

// Get org domain
String orgDomain = URL.getOrgDomainURL().toExternalForm().replace('.my.salesforce.com', '.lightning.force.com');

// Prepare thumbnails
Integer i = 0;
for (Storefront__c s : storefronts) {
    s.Thumbnail__c = orgDomain+ '/resource/storefront_thumbnails/'+ i +'.jpg';
    i ++;
    if (i > 20) {
        i = 0;
    }
}
// Update storefronts
update storefronts;

System.debug(
    LoggingLevel.INFO,
    'Updated thumbnails on ' +
        storefronts.size() +
        ' storefront(s).'
);
