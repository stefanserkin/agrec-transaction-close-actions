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
 * @description Retrieves a transaction by its record id, along with the receipt file link.
 * @date 2025
 ***********************************************************************/
public with sharing class TransactionCloseActionsSelector {

    private static final String RECEIPT_PREFIX = 'receipt-%';
    
    public static TREX1__Transaction__c getTransaction(String transactionId) {
        List<TREX1__Transaction__c> trxs = [
            SELECT Id, TREX1__Status__c, TREX1__Payment_Complete__c, TREX1__Account__c, TREX1__Contact__c, TREX1__Contact__r.Email,
                   (SELECT ContentDocumentId 
                      FROM ContentDocumentLinks
                     WHERE ContentDocument.Title LIKE :RECEIPT_PREFIX)
              FROM TREX1__Transaction__c
             WHERE Id = :transactionId
              WITH USER_MODE
             LIMIT 1
        ];

        if (trxs.isEmpty()) {
            throw new TransactionCloseActionsException('No transaction found with Id ' + transactionId);
        }

        return trxs[0];
    }

}