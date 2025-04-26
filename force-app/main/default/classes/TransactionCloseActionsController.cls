/*
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
/***********************************************************************
 * @description Controller for the payment page transaction close actions component.
 * @date 2025
 ***********************************************************************/
public with sharing class TransactionCloseActionsController {
    
    /**
     * Get transaction information with related receipt
     * @param recordId - Transaction record id
     * @return Transaction record
     */
    @AuraEnabled(cacheable=true)
    public static TREX1__Transaction__c getTransaction(String recordId) {
        try {
            return TransactionCloseActionsSelector.getTransaction(recordId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Send an email with the receipt as an attachment for a given transaction
     * @param recordId - Transaction record id
     * @return 'success'
     */
    @AuraEnabled(cacheable=false)
    public static String sendReceipt(String recordId) {
        try {
            ReceiptSender sender = new ReceiptSender(recordId);
            return sender.send();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}