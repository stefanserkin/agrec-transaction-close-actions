public inherited sharing class ReceiptSender {

    @TestVisible
    private static Traction_Rec_Receipt_Setting__mdt receiptSettings;
    private static EmailTemplate receiptEmailTemplate;
    private static OrgWideEmailAddress fromAddress;

    private Id recordId;
    private TREX1__Transaction__c trx;

    public ReceiptSender(Id recordId) {
        this.recordId = recordId;
        this.trx = TransactionCloseActionsSelector.getTransaction(recordId);
    }

    /**
     * Send an email with the receipt as an attachment for a given transaction
     * @return 'success'
     */
    public String send() {
        Messaging.SingleEmailMessage email = constructEmailMessage();
        email.setFileAttachments( constructEmailAttachments() );

        if (isOrgEmailEnabled()) {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        }

        return 'success';
    }

    private Traction_Rec_Receipt_Setting__mdt getReceiptSettings() {
        if (receiptSettings == null) {
            receiptSettings = Traction_Rec_Receipt_Setting__mdt.getAll()?.values().get(0);
        }
        return receiptSettings;
    }

    private Messaging.SingleEmailMessage constructEmailMessage() {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTemplateId( getReceiptEmailTemplateId() );
        email.setTargetObjectId(trx.TREX1__Contact__c);
        email.setWhatId(trx.Id);
        email.setSaveAsActivity(true);
        email.setUseSignature(false);
        if (getFromAddress() != null) {
            email.setOrgWideEmailAddressId( getFromAddress().Id );
        }
        return email;
    }

    private List<Messaging.EmailFileAttachment> constructEmailAttachments() {
        if (trx.ContentDocumentLinks.isEmpty()) {
            throw new TransactionCloseActionsException('No receipt found.');
        }
        ContentDocumentLink cdl = trx.ContentDocumentLinks[0];

        List<ContentVersion> contentVersions = [
            SELECT VersionData, FileExtension, ContentDocument.Title
              FROM ContentVersion 
             WHERE ContentDocumentId = :cdl.ContentDocumentId
               AND IsLatest = true
              WITH USER_MODE
        ];

        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        String fileName = !String.isBlank(getReceiptSettings().File_Name__c)
            ? getReceiptSettings().File_Name__c + '.' + contentVersions[0].FileExtension
            : contentVersions[0].ContentDocument.Title;
        attach.setFilename(fileName);
        attach.setBody(contentVersions[0].VersionData);
        return new List<Messaging.EmailFileAttachment>{attach};
    }

    @TestVisible
    private OrgWideEmailAddress getFromAddress() {
        String emailAddress = getReceiptSettings().From_Address__c;
        if (String.isBlank(emailAddress)) {
            return new OrgWideEmailAddress();
        }

        if (fromAddress == null) {
            List<OrgWideEmailAddress> addresses = [
                SELECT Id 
                  FROM OrgWideEmailAddress 
                 WHERE Address = :emailAddress
                  WITH USER_MODE
                 LIMIT 1
            ];
            if (!addresses.isEmpty()) {
                fromAddress = addresses[0];
            }
        }
        return fromAddress;
    }

    @TestVisible
    private Id getReceiptEmailTemplateId() {
        String emailTemplateName = getReceiptSettings().Email_Template_Name__c;
        if (receiptEmailTemplate == null) {
            List<EmailTemplate> emailTemplates = [
                SELECT Id, Subject, HtmlValue 
                  FROM EmailTemplate 
                 WHERE Name = :emailTemplateName
                  WITH SYSTEM_MODE
                 LIMIT 1
            ];
            if (emailTemplates.isEmpty()) {
                throw new TransactionCloseActionsException('Could not find email template: ' + emailTemplateName);
            }
            receiptEmailTemplate = emailTemplates[0];
        }
        return receiptEmailTemplate.Id;
    }

    @TestVisible
    private static Boolean isOrgEmailEnabled() {
        Boolean emailDeliverabilityEnabled = true;
        try {
            Messaging.reserveSingleEmailCapacity(1);
            Messaging.reserveMassEmailCapacity(1);
        } catch (System.NoAccessException e) {
            emailDeliverabilityEnabled = false;
        }
        return emailDeliverabilityEnabled;
    }

}