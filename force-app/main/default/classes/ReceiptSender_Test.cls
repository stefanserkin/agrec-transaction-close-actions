@IsTest
private class ReceiptSender_Test {
    
    @IsTest
    static void testSend() {
        Contact ct = agrec.TestDataFactory.createContacts(1).get(0);
        insert ct;

        TREX1__Transaction__c trx = agrec.TestDataFactory.createTransaction(ct.Id);
        insert trx;

        createReceipt(trx.Id);

        Test.startTest();
        ReceiptSender sender = new ReceiptSender(trx.Id);
        String result = sender.send();
        Test.stopTest();

        System.Assert.areEqual('success', result, 'Should have received a successful send result');
    }

    @IsTest
    static void testSendReceiptWithDefaultFileName() {
        EmailTemplate emailTemplate = [SELECT Name FROM EmailTemplate LIMIT 1];

        Traction_Rec_Receipt_Setting__mdt settings = new Traction_Rec_Receipt_Setting__mdt();
        settings.Email_Template_Name__c = emailTemplate.Name;
        settings.File_Name__c = 'TestReceipt';
        ReceiptSender.receiptSettings = settings;

        Contact ct = agrec.TestDataFactory.createContacts(1).get(0);
        insert ct;

        TREX1__Transaction__c trx = agrec.TestDataFactory.createTransaction(ct.Id);
        insert trx;

        createReceipt(trx.Id);

        Test.startTest();
        ReceiptSender sender = new ReceiptSender(trx.Id);
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

        ReceiptSender sender = new ReceiptSender(trx.Id);
        Test.startTest();
        OrgWideEmailAddress result = sender.getFromAddress();
        Test.stopTest();

        System.Assert.areEqual(addresses[0].Id, result.Id, 'Should have received Org Wide Email Address ' + addresses[0].Address);
    }

    @IsTest
    static void testSendWithInvalidRecordId() {
        Id fakeId = agrec.TriggerTestUtility.getFakeId(TREX1__Transaction__c.SObjectType);

        Test.startTest();
        try {
            ReceiptSender sender = new ReceiptSender(fakeId);
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
            ReceiptSender sender = new ReceiptSender(null);
            String result = sender.send();
            System.Assert.fail('Should have received an exception for no transaction found');
        } catch (Exception e) {
            System.Assert.isNotNull(e.getMessage(), 'Should have received an exception message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testSendWithNoReceipt() {
        Boolean isOrgEmailEnabled = ReceiptSender.isOrgEmailEnabled();
        
        Contact ct = agrec.TestDataFactory.createContacts(1).get(0);
        insert ct;

        TREX1__Transaction__c trx = agrec.TestDataFactory.createTransaction(ct.Id);
        insert trx;

        Test.startTest();
        try {
            ReceiptSender sender = new ReceiptSender(trx.Id);
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

        createReceipt(trx.Id);

        Test.startTest();
        try {
            ReceiptSender sender = new ReceiptSender(trx.Id);
            String result = sender.send();
            System.Assert.fail('Should have received an exception for the invalid template name');
        } catch (Exception e) {
            System.Assert.isNotNull(e.getMessage(), 'Should have received an exception message');
        }
        Test.stopTest();
    }

    private static ContentDocumentLink createReceipt(Id linkedEntityId) {
        ContentVersion cv = new ContentVersion();
        cv.title = 'receipt-012345';      
        cv.PathOnClient ='test';           
        cv.VersionData = Blob.valueOf('Test File Body');         
        insert cv;

        ContentVersion cvRefreshed = [SELECT Id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];

        ContentDocumentLink cdl = agrec.TestDataFactory.createContentDocumentLink(
            linkedEntityId,
            cvRefreshed.ContentDocumentId
        );
        insert cdl;
        return cdl;
    }

}