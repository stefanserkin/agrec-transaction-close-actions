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
import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { refreshApex } from '@salesforce/apex';
import { handleError, showToast } from 'c/lwcUtils';
import TransactionCloseModal from 'c/transactionCloseActionsModal';
import getTransaction from '@salesforce/apex/TransactionCloseActionsController.getTransaction';
import sendReceipt from '@salesforce/apex/TransactionCloseActionsController.sendReceipt';
import hasComponentAccess from '@salesforce/customPermission/Transaction_Close_Actions_Access';

export default class TransactionCloseActions extends NavigationMixin(LightningElement) {
    @api recordId;
    @api enableEmailReceipt = false;
    isAppPage = false;

    isLoading = false;
    error;

    channelName = '/event/agrec__Transaction_Close_Event__e';
    subscription = {};

    wiredTransaction = [];
    @track transaction;
    recipientContactId;

    @wire(CurrentPageReference)
    currentPageReference;

    connectedCallback() {
        this.registerErrorListener();

        if (!this.recordId && this.currentPageReference?.state?.c__recordId) {
            this.recordId = this.currentPageReference.state.c__recordId;
            this.isAppPage = true;
        }

        if (this.recordId) {
            this.handleSubscribe();
        } else {
            const errorMessage = 'The Transaction Close Actions toolbar could not load. No recordId found in context or URL.';
            console.error(errorMessage);
        }
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    get isComponentVisible() {
        return hasComponentAccess;
    }

    get navigationButtonGroupStyle() {
        return this.enableEmailReceipt ? 'slds-var-m-around_medium slds-float_right' : 'slds-var-m-around_medium slds-align_absolute-center';
    }

    /**
     * empApi subscription
     */
    
    handleSubscribe() {
        const messageCallback = (response) => {
            const recordIdToRefresh = response.data.payload['agrec__Record_ID__c'];
            if (recordIdToRefresh === this.recordId) {
                refreshApex(this.wiredTransaction);
            }
        };

        subscribe(this.channelName, -1, messageCallback).then((response) => {
            this.subscription = response;
        });
    }

    handleUnsubscribe() {
        unsubscribe(this.subscription, (response) => {
            console.log('unsubscribe() response: ', JSON.stringify(response));
        });
    }

    registerErrorListener() {
        onError((error) => {
            handleError(this, error, 'Error registering listener for transaction close actions');
        });
    }

    /**
     * Get Transaction
     */

    @wire(getTransaction, { recordId: '$recordId' })
    wiredTransactionResult(result) {
        this.isLoading = true;
        this.wiredTransaction = result;

        if (result.data) {
            this.transaction = result.data;
            if (this.transaction.TREX1__Contact__c && this.transaction.TREX1__Contact__r.Email) {
                this.recipientContactId = this.transaction.TREX1__Contact__c;
            }
            this.error = undefined;
            this.isLoading = false;
        } else if (result.error) {
            this.transaction = undefined;
            handleError(this, result.error, 'Error retrieving transaction');
            this.isLoading = false;
        }
    }

    get paymentIsComplete() {
        return this.transaction && this.transaction.TREX1__Status__c === 'Close' && this.transaction.TREX1__Payment_Complete__c;
    }

    get contactNavigationIsDisabled() {
        return !this.transaction || !this.transaction.TREX1__Contact__c;
    }

    get accountNavigationIsDisabled() {
        return !this.transaction || !this.transaction.TREX1__Account__c;
    }

    get transactionNavigationIsDisabled() {
        return !this.transaction || !this.isAppPage;
    }
    
    get sendReceiptIsDisabled() {
        return !this.transaction || !this.transaction.ContentDocumentLinks || this.transaction.ContentDocumentLinks.length === 0;
    }

    /**
     * Navigation events
     */

    handleGoToAccount() {
        this.navigateToRecord(this.transaction.TREX1__Account__c);
    }

    handleGoToContact() {
        this.navigateToRecord(this.transaction.TREX1__Contact__c);
    }

    handleGoToTransaction() {
        this.navigateToRecord(this.transaction.Id);
    }

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    /**
     * Email Receipt
     */

    async handleEmailReceipt() {
        const result = await TransactionCloseModal.open({
            size: 'small',
            description: 'Set the email address to send the receipt to',
            recipientContactId: this.recipientContactId,
            isSelectAlternateContactMode: !this.recipientContactId
        });

        if (result) {
            this.recipientContactId = result;
            this.handleSendReceipt();
        }
    }

    handleSendReceipt() {
        this.isLoading = true;
        sendReceipt({transactionId: this.transaction.Id, recipientContactId: this.recipientContactId})
            .then(() => {
                showToast(this, 'Receipt Sent', 'The receipt was sent successfully.', 'success');
                this.isLoading = false;
            })
            .catch(error => {
                handleError(this, error, 'Error sending receipt');
                this.isLoading = false;
            });
    }

}