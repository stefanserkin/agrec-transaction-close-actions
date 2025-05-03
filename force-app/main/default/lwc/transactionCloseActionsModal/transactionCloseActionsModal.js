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
import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import NAME_FIELD from '@salesforce/schema/Contact.Name';
import EMAIL_FIELD from '@salesforce/schema/Contact.Email';
import ACCOUNT_FIELD from '@salesforce/schema/Contact.AccountId';

export default class TransactionCloseActionsModal extends LightningModal {
    @api recipientContactId;
    @api isSelectAlternateContactMode = false;

    nameField = NAME_FIELD;
    emailField = EMAIL_FIELD;
    accountField = ACCOUNT_FIELD;

    searchContactsFilter = {
        criteria: [
            {
                fieldPath: 'Email',
                operator: 'ne',
                value: null,
            }
        ]
    };

    searchContactsDisplayInfo = {
        primaryField: 'Name',
        additionalFields: ['Email']
    };

    searchContactsMatchingInfo = {
        primaryField: { fieldPath: 'Name', mode: 'contains' },
        additionalFields: [{ fieldPath: 'Email', mode: 'contains' }]
    };

    get toggleSelectAlternateContactLabel() {
        return this.isSelectAlternateContactMode ? 'Cancel' : 'Change Recipient Contact';
    }

    get toggleSelectAlternateContactIconName() {
        return this.isSelectAlternateContactMode ? 'utility:leave_conference' : 'utility:change_owner';
    }

    get toggleSelectAlternateContactVariant() {
        return this.isSelectAlternateContactMode ? 'destructive-text' : 'brand-outline';
    }

    get sendIsDisabled() {
        return !this.recipientContactId;
    }

    handleContactChange(event) {
        this.recipientContactId = event.detail.recordId;
        this.toggleSelectAlternateContactMode();
    }

    toggleSelectAlternateContactMode() {
        if (this.isSelectAlternateContactMode && !this.recipientContactId) {
            this.close();
        }
        this.isSelectAlternateContactMode = !this.isSelectAlternateContactMode;
    }

    handleSend() {
        this.close(this.recipientContactId);
    }

}