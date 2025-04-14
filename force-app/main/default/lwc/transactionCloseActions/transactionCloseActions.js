import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { refreshApex } from '@salesforce/apex';
import TransactionCloseModal from 'c/transactionCloseActionsModal';
import getTransaction from '@salesforce/apex/TransactionCloseActionsController.getTransaction';
import sendReceipt from '@salesforce/apex/TransactionCloseActionsController.sendReceipt';

export default class TransactionCloseActions extends NavigationMixin(LightningElement) {
    @api enableEmailReceipt = false;

    isLoading = false;
    error;

    channelName = '/event/agrec__Transaction_Close_Event__e';
    subscription = {};

    recordId;

    wiredTransaction = [];
    @track transaction;
    toAddress;

    @wire(CurrentPageReference)
    currentPageReference;

    connectedCallback() {
        this.registerErrorListener();
        this.recordId = this.currentPageReference.state.c__recordId;
        this.handleSubscribe();
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    /**
     * empApi subscription
     */

    handleSubscribe() {
        const messageCallback = (response) => {
            console.log('New message received: ', JSON.stringify(response));
            // Response contains the payload of the new message received
            const recordIdToRefresh = response.data.payload['agrec__Record_ID__c'];
            if (recordIdToRefresh === this.recordId) {
                refreshApex(this.wiredTransaction);
            }
        };

        subscribe(this.channelName, -1, messageCallback).then((response) => {
            console.log('Subscription request sent to: ', JSON.stringify(response.channel));
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
        this.isLoading = true;
        this.wiredTransaction = result;

        if (result.data) {
            this.transaction = result.data;
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

    get transactionIsClosed() {
        return this.transaction && this.transaction.TREX1__Status__c === 'Close';
    }

    get contactNavigationIsDisabled() {
        return !this.transaction || !this.transaction.TREX1__Contact__c;
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

        console.log(result);
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