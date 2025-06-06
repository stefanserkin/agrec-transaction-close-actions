/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description 
 * Prepare receipt email from Traction Rec Receipt Setting custom metadata
 * 
 * @date 2025
 * @author
 * Asphalt Green Data and Information Systems
 ***********************************************************************/
public without sharing class ReceiptSender {

    @TestVisible
    private static Traction_Rec_Receipt_Setting__mdt receiptSettings;
    private static EmailTemplate receiptEmailTemplate;
    private static OrgWideEmailAddress fromAddress;

    @TestVisible
    private static List<Messaging.SendEmailResult> testSendResults;

    private Id transactionId;
    private Id recipientContactId;
    private TREX1__Transaction__c trx;

    public ReceiptSender(Id transactionId, Id recipientContactId) {
        this.transactionId = transactionId;
        this.recipientContactId = recipientContactId;
        this.trx = TransactionCloseActionsSelector.getTransaction(transactionId);
    }

    /**
     * Send an email with the receipt as an attachment for a given transaction
     * @return 'success' on successful send
     */
    public String send() {
        if (!agrec.Util.isOrgEmailEnabled()) {
            throw new TransactionCloseActionsException('Email deliverability is not enabled in this org');
        }

        Messaging.SingleEmailMessage email = constructEmailMessage();
        email.setFileAttachments( constructEmailAttachments() );
        handleSendResults( sendEmail(email) );

        return 'success';
    }

    private Messaging.SingleEmailMessage constructEmailMessage() {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTemplateId( getReceiptEmailTemplateId() );
        email.setTargetObjectId(recipientContactId);
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
              WITH SYSTEM_MODE
        ];

        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        String fileName = !String.isBlank(getReceiptSettings().File_Name__c)
            ? getReceiptSettings().File_Name__c + '.' + contentVersions[0].FileExtension
            : contentVersions[0].ContentDocument.Title;
        attach.setFilename(fileName);
        attach.setBody(contentVersions[0].VersionData);
        return new List<Messaging.EmailFileAttachment>{attach};
    }

    private List<Messaging.SendEmailResult> sendEmail(Messaging.SingleEmailMessage email) {
        if (testSendResults != null) {
            return testSendResults;
        }
        return Messaging.sendEmail( new List<Messaging.SingleEmailMessage>{email} );
    }

    private static void handleSendResults(List<Messaging.SendEmailResult> sendResults) {
        if (!sendResults[0].isSuccess()) {
            List<Messaging.SendEmailError> errors = sendResults[0].getErrors();
            String message = errors != null && !errors.isEmpty() ? errors[0].getMessage() : 'Unknown error';
            throw new TransactionCloseActionsException('Failed to send receipt. ' + message);
        }
    }

    /**
     * Org settings utilities
     */

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
                  WITH SYSTEM_MODE
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
                 WHERE DeveloperName = :emailTemplateName OR Name = :emailTemplateName
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

    private Traction_Rec_Receipt_Setting__mdt getReceiptSettings() {
        if (receiptSettings == null) {
            receiptSettings = Traction_Rec_Receipt_Setting__mdt.getAll()?.values().get(0);
        }
        return receiptSettings;
    }

}