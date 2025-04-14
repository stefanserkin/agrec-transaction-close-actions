import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class TransactionCloseActionsModal extends LightningModal {
    @api toAddress;

    handleToAddressChange(event) {
        this.toAddress = event.target.value;
    }

    handleSend() {
        this.close(this.toAddress);
    }
}