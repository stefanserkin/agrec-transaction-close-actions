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
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { refreshApex } from '@salesforce/apex';
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
    toAddress;

    @wire(CurrentPageReference)
    currentPageReference;

    connectedCallback() {
        this.registerErrorListener();

        if (!this.recordId && this.currentPageReference?.state?.c__recordId) {
            console.log('::: settings recordid to ',this.currentPageReference.state.c__recordId);
            this.recordId = this.currentPageReference.state.c__recordId;
            this.isAppPage = true;
        }

        if (this.recordId) {
            console.log('has record id. Subscribing to platform event channel');
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

    /**
     * empApi subscription
     */

    handleSubscribe() {
        const messageCallback = (response) => {
            // Response contains the payload of the new message received
            console.log(':::: received payload --> ', JSON.stringify(response.data.payload));
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
        // Invoke unsubscribe method of empApi
        unsubscribe(this.subscription, (response) => {
            console.log('unsubscribe() response: ', JSON.stringify(response));
            // Response is true for successful unsubscribe
        });
    }

    registerErrorListener() {
        // Invoke onError empApi method
        onError((error) => {
            console.log('Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
        });
    }

    /**
     * Get Transaction
     */

    @wire(getTransaction, { recordId: '$recordId' })
    wiredTransactionResult(result) {
        console.log(':::: looking for transaction');
        console.log('::: user has permission ? ' + this.isComponentVisible);
        this.isLoading = true;
        this.wiredTransaction = result;

        if (result.data) {
            this.transaction = result.data;
            console.log(':::: transaction --> ', JSON.stringify(this.transaction));
            this.toAddress = this.transaction.TREX1__Contact__r.Email || '';
            this.error = undefined;
            this.isLoading = false;
        } else if (result.error) {
            this.transaction = undefined;
            this.error = result.error;
            console.error(this.error);
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
        return !this.transaction || !this.toAddress ||
               !this.transaction.ContentDocumentLinks || this.transaction.ContentDocumentLinks.length === 0;
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

    navigateToRecord(recId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recId,
                actionName: 'view'
            }
        });
    }

    /**
     * Email Receipt
     */

    handleToAddressChange(event) {
        this.toAddress = event.detail.toAddress;
    }

    async handleEmailReceipt() {
        const result = await TransactionCloseModal.open({
            size: 'small',
            description: 'Set the email address to send the receipt to',
            toAddress: this.toAddress
        });

        if (result) {
            this.toAddress = result;
            this.handleSendReceipt();
        }
    }

    handleSendReceipt() {
        this.isLoading = true;
        sendReceipt({recordId: this.transaction.Id})
            .then(() => {
                this.showToast(
                    'Receipt Sent',
                    'The receipt was sent successfully.',
                    'success'
                );
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error;
                console.error(this.error);
                this.showToast(
                    'Error Sending Receipt',
                    'There was an error sending the receipt.',
                    'error'
                );
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title,
            message,
            variant
        })
        this.dispatchEvent(toastEvent);
    }

    get navigationButtonGroupStyle() {
        return this.enableEmailReceipt ? 'slds-var-m-around_medium slds-float_right' : 'slds-var-m-around_medium slds-align_absolute-center';
    }

}