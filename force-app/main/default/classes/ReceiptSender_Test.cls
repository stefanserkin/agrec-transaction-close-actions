@IsTest
private class ReceiptSender_Test {
    
    @IsTest
    static void testSend() {
        Contact ct = agrec.TestDataFactory.createContacts(1).get(0);
        insert ct;

        TREX1__Transaction__c trx = agrec.TestDataFactory.createTransaction(ct.Id);
        insert trx;

        List<ContentDocumentLink> cdls = agrec.TestDataFactory.createReceipts(new List<SObject>{trx});
        insert cdls;

        Test.startTest();
        ReceiptSender sender = new ReceiptSender(trx.Id, ct.Id);
        String result = sender.send();
        Test.stopTest();

        System.Assert.areEqual('success', result, 'Should have received a successful send result');
    }

    @IsTest
    static void testSendReceiptWithDefinedFileName() {
        EmailTemplate emailTemplate = [SELECT Name FROM EmailTemplate LIMIT 1];

        Traction_Rec_Receipt_Setting__mdt settings = new Traction_Rec_Receipt_Setting__mdt();
        settings.Email_Template_Name__c = emailTemplate.Name;
        settings.File_Name__c = 'TestReceipt';
        ReceiptSender.receiptSettings = settings;

        Contact ct = agrec.TestDataFactory.createContacts(1).get(0);
        insert ct;

        TREX1__Transaction__c trx = agrec.TestDataFactory.createTransaction(ct.Id);
        insert trx;

        List<ContentDocumentLink> cdls = agrec.TestDataFactory.createReceipts(new List<SObject>{trx});
        insert cdls;

        Test.startTest();
        ReceiptSender sender = new ReceiptSender(trx.Id, ct.Id);
        String result = sender.send();
        Test.stopTest();

        System.Assert.areEqual('success', result, 'Should have received a successful send result');
    }

    @IsTest
    static void testSendReceiptWithDefaultFileName() {
        EmailTemplate emailTemplate = [SELECT Name FROM EmailTemplate LIMIT 1];

        Traction_Rec_Receipt_Setting__mdt settings = new Traction_Rec_Receipt_Setting__mdt();
        settings.Email_Template_Name__c = emailTemplate.Name;
        ReceiptSender.receiptSettings = settings;

        Contact ct = agrec.TestDataFactory.createContacts(1).get(0);
        insert ct;

        TREX1__Transaction__c trx = agrec.TestDataFactory.createTransaction(ct.Id);
        insert trx;

        List<ContentDocumentLink> cdls = agrec.TestDataFactory.createReceipts(new List<SObject>{trx});
        insert cdls;

        Test.startTest();
        ReceiptSender sender = new ReceiptSender(trx.Id, ct.Id);
        String result = sender.send();
        Test.stopTest();

        System.Assert.areEqual('success', result, 'Should have received a successful send result');
    }

    @IsTest
    static void testSendWithOrgWideEmailAddress() {
        List<OrgWideEmailAddress> addresses = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress LIMIT 1];

        if (addresses.isEmpty()) {
            return;
        }

        Traction_Rec_Receipt_Setting__mdt settings = new Traction_Rec_Receipt_Setting__mdt();
        settings.From_Address__c = addresses[0].Address;
        ReceiptSender.receiptSettings = settings;

        Contact ct = agrec.TestDataFactory.createContacts(1).get(0);
        insert ct;
        TREX1__Transaction__c trx = agrec.TestDataFactory.createTransaction(ct.Id);
        insert trx;

        ReceiptSender sender = new ReceiptSender(trx.Id, ct.Id);
        Test.startTest();
        OrgWideEmailAddress result = sender.getFromAddress();
        Test.stopTest();

        System.Assert.areEqual(addresses[0].Id, result.Id, 'Should have received Org Wide Email Address ' + addresses[0].Address);
    }

    @IsTest
    static void testSendWithInvalidRecordId() {
        Id fakeTransactionId = agrec.TriggerTestUtility.getFakeId(TREX1__Transaction__c.SObjectType);
        Id fakeContactId = agrec.TriggerTestUtility.getFakeId(Contact.SObjectType);

        Test.startTest();
        try {
            ReceiptSender sender = new ReceiptSender(fakeTransactionId, fakeContactId);
            String result = sender.send();
            System.Assert.fail('Should have received an exception for no transaction found');
        } catch (Exception e) {
            System.Assert.isNotNull(e.getMessage(), 'Should have received an exception message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testSendWithNullRecordId() {
        Test.startTest();
        try {
            ReceiptSender sender = new ReceiptSender(null, null);
            String result = sender.send();
            System.Assert.fail('Should have received an exception for no transaction found');
        } catch (Exception e) {
            System.Assert.isNotNull(e.getMessage(), 'Should have received an exception message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testSendWithNoReceipt() {
        Contact ct = agrec.TestDataFactory.createContacts(1).get(0);
        insert ct;

        TREX1__Transaction__c trx = agrec.TestDataFactory.createTransaction(ct.Id);
        insert trx;

        Test.startTest();
        try {
            ReceiptSender sender = new ReceiptSender(trx.Id, ct.Id);
            String result = sender.send();
            System.Assert.fail('Should have received an exception for the lack of receipt');
        } catch (Exception e) {
            System.Assert.isNotNull(e.getMessage(), 'Should have received an exception message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testInvalidEmailTemplate() {
        Traction_Rec_Receipt_Setting__mdt settings = new Traction_Rec_Receipt_Setting__mdt();
        settings.Email_Template_Name__c = 'RuhRoh';
        ReceiptSender.receiptSettings = settings;

        Contact ct = agrec.TestDataFactory.createContacts(1).get(0);
        insert ct;

        TREX1__Transaction__c trx = agrec.TestDataFactory.createTransaction(ct.Id);
        insert trx;

        List<ContentDocumentLink> cdls = agrec.TestDataFactory.createReceipts(new List<SObject>{trx});
        insert cdls;

        Test.startTest();
        try {
            ReceiptSender sender = new ReceiptSender(trx.Id, ct.Id);
            String result = sender.send();
            System.Assert.fail('Should have received an exception for the invalid template name');
        } catch (Exception e) {
            System.Assert.isNotNull(e.getMessage(), 'Should have received an exception message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testUnsuccessfulEmailResult() {
        EmailTemplate emailTemplate = [SELECT Name FROM EmailTemplate LIMIT 1];

        Traction_Rec_Receipt_Setting__mdt settings = new Traction_Rec_Receipt_Setting__mdt();
        settings.Email_Template_Name__c = emailTemplate.Name;
        settings.File_Name__c = 'TestReceipt';
        ReceiptSender.receiptSettings = settings;

        Contact ct = agrec.TestDataFactory.createContacts(1).get(0);
        insert ct;

        TREX1__Transaction__c trx = agrec.TestDataFactory.createTransaction(ct.Id);
        insert trx;

        List<ContentDocumentLink> cdls = agrec.TestDataFactory.createReceipts(new List<SObject>{trx});
        insert cdls;

        Messaging.SendEmailResult mockResult = getMockFailedResult();
        ReceiptSender.testSendResults = new List<Messaging.SendEmailResult>{mockResult};

        Test.startTest();
        ReceiptSender sender = new ReceiptSender(trx.Id, ct.Id);
        try {
            sender.send();
            System.Assert.fail('Expected exception was not thrown');
        } catch (TransactionCloseActionsException e) {
            System.assert(e.getMessage().contains('Failed to send receipt'), 'Unexpected error message: ' + e.getMessage());
            System.debug('Caught expected exception: ' + e.getMessage());
        }
        Test.stopTest();
    }

    private static Messaging.SendEmailResult getMockFailedResult() {
        String payload = '{' +
            '  "success": false,' +
            '  "errors": [' +
            '    {' +
            '      "statusCode": "REQUIRED_FIELD_MISSING",' +
            '      "message": "Missing required field"' +
            '    }' +
            '  ]' +
            '}';

        Messaging.SendEmailResult mockResult = (Messaging.SendEmailResult) JSON.deserialize(
            payload, 
            Messaging.SendEmailResult.class
        );
        return mockResult;
    }

}