/**
 * Service class for retrieving `Contact` records representing customers.
 */
public virtual with sharing class CustomerService {
  @TestVisible
  private final static Integer DEFAULT_CUSTOMER_LIMIT = 10;

  /**
   * Retrieves the first customers, ordered by name.
   * @param recordLimit Optional maximum number of customers to return. Defaults to 10.
   * @return A list of matching `Contact` records.
   */
  public virtual List<Contact> getCustomers(Integer recordLimit) {
    Integer resolvedLimit = (recordLimit == null || recordLimit <= 0) ? DEFAULT_CUSTOMER_LIMIT : recordLimit;

    return [
      SELECT Id, Name, Email, Phone, MailingStreet, MailingCity, MailingStateCode, MailingPostalCode, MailingCountryCode
      FROM Contact
      WITH USER_MODE
      ORDER BY Name
      LIMIT :resolvedLimit
    ];
  }

  /**
   * Retrieves a customer record by its name.
   * @param customerName The name of the customer to retrieve.
   * @return The matching `Contact` record.
   */
  public virtual Contact getCustomerFromName(String customerName) {
    if (String.isBlank(customerName)) {
      throw new CustomerException('A customer name must be provided.');
    }

    // Query for customers matching the provided name
    String likeName = '%' + customerName + '%';
    List<Contact> customers = [
      SELECT Id, Name, Email, Phone, MailingStreet, MailingCity, MailingStateCode, MailingPostalCode, MailingCountryCode
      FROM Contact
      WHERE Name LIKE :likeName
      WITH USER_MODE
    ];

    if (customers.isEmpty()) {
      throw new CustomerException('No customer found with name: ' + customerName);
    }

    // Single match: return it directly
    if (customers.size() == 1) {
      return customers[0];
    }

    // Multiple matches: resolve to the exact name match or surface the options
    Set<String> customerNames = new Set<String>();
    for (Contact customer : customers) {
      if (customer.Name == customerName) {
        return customer;
      }
      customerNames.add(customer.Name);
    }

    // No exact match: surface the possible matches
    throw new CustomerException('Multiple customers found. Possible matches: ' + String.join(customerNames, ', '));
  }

  /**
   * Exception thrown when a customer cannot be found or resolved.
   */
  public class CustomerException extends Exception {
  }
}
