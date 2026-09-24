/**
 * Orchestrates the AI job that regenerates storefront review summaries.
 */
public with sharing class StoreReviewSummaryAiJob {
  public static final String PROMPT_TEMPLATE_NAME = 'Customer_Review_Summary_Flex';

  /**
   * Creates and starts an AIJobRun that summarizes customer reviews for storefronts.
   * @param forceRefresh Whether to include storefronts that already have a review summary
   */
  public static void startJob(Boolean forceRefresh) {
    // Create job draft
    AIJobRun jobRun = new AIJobRun(
      JobType = 'PromptTemplate',
      Target = PROMPT_TEMPLATE_NAME,
      Label = 'Refresh customer review summaries'
    );
    insert as user jobRun;

    try {
      // Create job run items for storefronts
      List<AiJobRunItem> jobRunItems = new List<AiJobRunItem>();
      List<Storefront__c> storefronts = getStorefrontsToProcess(forceRefresh);
      for (Storefront__c storefront : storefronts) {
        String promptInput = '{"Input:storefront": {"id":"' + storefront.Id + '"}}';
        AiJobRunItem runItem = new AiJobRunItem(AiJobRunId = jobRun.Id, Status = 'Ready', Input = promptInput);
        jobRunItems.add(runItem);
      }
      insert as user jobRunItems;

      // Start job
      jobRun.Status = 'ReadyToStart';
      update as user jobRun;
      System.debug('Job started to summmarize ' + storefronts.size() + ' storefront reviews: ' + jobRun.Id);
    } catch (Exception e) {
      delete as user jobRun;
      System.debug(LoggingLevel.ERROR, 'Error starting job: ' + e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * Applies the AI-generated review summaries from a completed job run to their storefronts.
   * @param jobRunId The Id of the completed AIJobRun
   */
  public static void handleCompletedJob(Id jobRunId) {
    // Invoked by AiJobRunTriggerHandler when the platform's AI job engine marks the job
    // Completed - not by the requesting user - so this intentionally runs in system mode.
    // Get job run items
    List<AiJobRunItem> jobRunItems = [
      SELECT Id, Input, Response
      FROM AiJobRunItem
      WHERE AiJobRunId = :jobRunId AND Status = 'Completed'
      WITH SYSTEM_MODE
    ];
    System.debug('Job run items: ' + jobRunItems.size());

    // Map of storefront ID to review summary
    Map<Id, String> storeIdToSummary = new Map<Id, String>();
    for (AiJobRunItem jobRunItem : jobRunItems) {
      try {
        // Parse input JSON to extract storefront ID
        Map<String, Object> inputMap = (Map<String, Object>) JSON.deserializeUntyped(jobRunItem.Input);
        Map<String, Object> storefrontInput = (Map<String, Object>) inputMap.get('Input:storefront');
        String storefrontId = (String) storefrontInput.get('id');

        // Parse response JSON to extract promptResponse
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(jobRunItem.Response);
        String promptResponse = (String) responseMap.get('promptResponse');

        storeIdToSummary.put(storefrontId, promptResponse);
      } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, 'Error processing job run item: ' + e.getMessage());
      }
    }

    // Stop if no storefronts to update
    if (storeIdToSummary.isEmpty()) {
      System.debug('No storefronts to update');
      return;
    }

    // Update storefronts with review summaries
    try {
      Set<Id> storefrontIds = storeIdToSummary.keySet();
      List<Storefront__c> storefrontsToUpdate = [
        SELECT Id, Review_Summary__c
        FROM Storefront__c
        WHERE Id IN :storefrontIds
        WITH SYSTEM_MODE
      ];
      for (Storefront__c storefront : storefrontsToUpdate) {
        storefront.Review_Summary__c = storeIdToSummary.get(storefront.Id);
      }
      update as system storefrontsToUpdate;
      System.debug('Updated ' + storefrontsToUpdate.size() + ' storefronts with review summaries');
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'Error updating storefronts: ' + e.getMessage());
    }
  }

  private static List<Storefront__c> getStorefrontsToProcess(Boolean forceRefresh) {
    List<Storefront__c> storefronts;
    if (forceRefresh) {
      // Get all storefronts
      storefronts = [
        SELECT Id
        FROM Storefront__c
        WHERE Id IN (SELECT Storefront__c FROM Review__c)
        WITH USER_MODE
      ];
    } else {
      // Exclude storefronts that already have a summary
      List<Storefront__c> allStorefronts = [
        SELECT Id, Review_Summary__c
        FROM Storefront__c
        WHERE Id IN (SELECT Storefront__c FROM Review__c)
        WITH USER_MODE
      ];
      storefronts = new List<Storefront__c>();
      for (Storefront__c storefront : allStorefronts) {
        if (storefront.Review_Summary__c == null) {
          storefronts.add(storefront);
        }
      }
    }
    return storefronts;
  }
}
