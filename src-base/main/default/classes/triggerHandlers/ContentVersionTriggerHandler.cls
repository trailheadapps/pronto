/**
 * Trigger handler for ContentVersion records that extracts menu items from
 * documents attached to Storefront__c records.
 */
public with sharing class ContentVersionTriggerHandler {
  private static final String EXCLUDE_STOREFRONT_NAME_PATTERN = 'Fusion';
  private static final String IMPORTED_MENU_NAME = 'Imported Menu';

  /**
   * Handles after insert events for ContentVersion records
   * Checks if the ContentVersion is attached to a Storefront__c record and runs menu extraction
   * @param newContentVersions List of newly inserted ContentVersion records
   */
  public static void handleAfterInsert(List<ContentVersion> newContentVersions) {
    System.debug('Processing: ' + newContentVersions.size() + ' new ContentVersion records');
    // Get ContentDocument IDs from the ContentVersion records
    Set<Id> contentDocumentIds = new Set<Id>();
    for (ContentVersion cv : newContentVersions) {
      if (cv.ContentDocumentId != null) {
        contentDocumentIds.add(cv.ContentDocumentId);
      }
    }
    if (contentDocumentIds.isEmpty()) {
      return;
    }

    // Query for ContentDocumentLink records to find Storefront__c attachments
    List<ContentDocumentLink> contentDocumentLinks = [
      SELECT Id, ContentDocumentId, LinkedEntityId, LinkedEntity.Type
      FROM ContentDocumentLink
      WHERE ContentDocumentId IN :contentDocumentIds
      WITH USER_MODE
    ];

    // Filter out ContentDocumentLinks that are not linked to Storefront__c records
    List<ContentDocumentLink> storefrontLinks = new List<ContentDocumentLink>();
    for (ContentDocumentLink cdl : contentDocumentLinks) {
      if (cdl.LinkedEntity.Type == 'Storefront__c') {
        storefrontLinks.add(cdl);
      }
    }
    if (storefrontLinks.isEmpty()) {
      return;
    }

    // Extract Storefront IDs
    Set<Id> storefrontIds = new Set<Id>();
    for (ContentDocumentLink cdl : storefrontLinks) {
      storefrontIds.add(cdl.LinkedEntityId);
    }

    // Query for Storefront records
    List<Storefront__c> storefronts = [
      SELECT Id, Name
      FROM Storefront__c
      WHERE Id IN :storefrontIds
      WITH USER_MODE
    ];
    if (storefronts.isEmpty()) {
      return;
    }
    System.debug('Processing documents added to the following Storefronts: ' + JSON.serialize(storefronts));

    // Process each storefront for menu extraction
    for (Storefront__c storefront : storefronts) {
      // Only process storefronts that do not match the exclude pattern
      if (!storefront.Name.contains(EXCLUDE_STOREFRONT_NAME_PATTERN)) {
        processStorefront(storefront.Id);
      }
    }
  }

  @future
  private static void processStorefront(Id storefrontId) {
    System.debug('Processing menu extraction for storefront: ' + storefrontId);
    Storefront__c storefront = [SELECT Id, Name FROM Storefront__c WHERE Id = :storefrontId WITH USER_MODE];
    String promptResponse = callExtractMenuPrompt(storefront);
    System.debug('Prompt Response: ' + promptResponse);
    parseAndInsertMenuItems(promptResponse, storefront);
    deleteAttachments(storefrontId);
  }

  private static void deleteAttachments(Id storefrontId) {
    List<ContentDocumentLink> attachments = [
      SELECT Id, ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :storefrontId
      WITH USER_MODE
    ];
    Set<Id> contentDocumentIds = new Set<Id>();
    for (ContentDocumentLink cdl : attachments) {
      contentDocumentIds.add(cdl.ContentDocumentId);
    }
    delete [SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentIds];
  }

  /**
   * Processes menu extraction for a single storefront using the Extract_Menu prompt template
   * @param storefrontRecord The Storefront__c record to process
   * @return The response from the prompt template
   */
  private static String callExtractMenuPrompt(Storefront__c storefrontRecord) {
    try {
      // Create inputs
      Map<String, Object> storefront = new Map<String, Object>();
      storefront.put('id', storefrontRecord.Id);
      ConnectApi.WrappedValue storefrontValue = new ConnectApi.WrappedValue();
      storefrontValue.value = storefront;
      Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
      inputParams.put('Input:storefront', storefrontValue);

      // Configure invocation parameters
      ConnectApi.EinsteinPromptTemplateGenerationsInput executeTemplateInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
      executeTemplateInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
      executeTemplateInput.additionalConfig.applicationName = 'PromptBuilderPreview';
      executeTemplateInput.isPreview = false;
      executeTemplateInput.inputParams = inputParams;

      // Call the prompt template
      ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput = ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
        'Extract_Menu',
        executeTemplateInput
      );
      ConnectApi.EinsteinLLMGenerationItemOutput response = generationsOutput.generations[0];
      return response.text;
    } catch (Exception e) {
      throw new MenuParsingException(
        'Error running menu extraction prompt for storefront ' +
          storefrontRecord.Name +
          ' (' +
          storefrontRecord.Id +
          '): ' +
          e.getMessage()
      );
    }
  }

  /**
   * Parses the menu items from the prompt response and inserts them into the database
   * @param promptResponse The response from the prompt template
   * @param storefrontRecord The Storefront__c record to insert the menu items into
   */
  private static void parseAndInsertMenuItems(String promptResponse, Storefront__c storefrontRecord) {
    List<Menu_Item__c> menuItems;
    try {
      MenuContent menuContent = (MenuContent) JSON.deserializeStrict(promptResponse, MenuContent.class);
      menuItems = menuContent.Menu_Items;
    } catch (Exception e) {
      throw new MenuParsingException(
        'Error parsing menu items for storefront ' +
          storefrontRecord.Name +
          ' (' +
          storefrontRecord.Id +
          '): ' +
          e.getMessage()
      );
    }

    // Retrieve or create a menu
    Menu__c menu = getMenuFromStorefrontAndName(storefrontRecord, IMPORTED_MENU_NAME);
    if (menu == null) {
      // Create a menu
      menu = new Menu__c(
        Menu_Display_Name__c = IMPORTED_MENU_NAME,
        Description__c = 'Standard menu imported from a PDF file',
        Storefront__c = storefrontRecord.Id,
        Active__c = true
      );
      insert as user menu;
    } else {
      // Delete existing menu items
      delete [SELECT Id FROM Menu_Item__c WHERE Menu__c = :menu.Id];
    }

    // Add menu items
    for (Menu_Item__c menuItem : menuItems) {
      menuItem.Menu__c = menu.Id;
      menuItem.Available__c = true;
    }
    insert as user menuItems;
  }

  // Get menu from storefront and menu name
  private static Menu__c getMenuFromStorefrontAndName(Storefront__c storefront, String menuName) {
    List<Menu__c> menus = [
      SELECT Id
      FROM Menu__c
      WHERE Storefront__c = :storefront.Id AND Menu_Display_Name__c = :menuName
      WITH USER_MODE
    ];
    if (menus.isEmpty()) {
      return null;
    }
    return menus[0];
  }

  private class MenuContent {
    public List<Menu_Item__c> Menu_Items;
  }

  /**
   * Exception thrown when menu items cannot be extracted or parsed from a prompt response.
   */
  public class MenuParsingException extends Exception {
  }
}
