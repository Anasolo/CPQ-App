import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

import QUOTE_OBJECT from '@salesforce/schema/SF_Quote__c';
import OPP_ID from '@salesforce/schema/SF_Quote__c.Opportunity__c';
import EXP_DATE from '@salesforce/schema/SF_Quote__c.Expiration_Date__c';



export default class SF_createQuote extends NavigationMixin(LightningElement) {

    @api recordId;
    @api isLoaded = false;
    @track hasRendered = true;
    date = new Date(new Date().setDate(new Date().getDate() + 7));



    renderedCallback() {
        if (this.recordId !== undefined && this.hasRendered) {
            this.createQuote();
        }
    }
    createQuote() {
        const fields = {};
        fields[EXP_DATE.fieldApiName] = this.date
        fields[OPP_ID.fieldApiName] = this.recordId;
        const recordInput = { apiName: QUOTE_OBJECT.objectApiName, fields };

        createRecord(recordInput)
        .then(quote => {
            this.hasRendered = false;
            console.log('quote', quote.id);
            this.isLoaded = !this.isLoaded;
        
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Quote has created!',
                    variant: 'Success',
                }),
            );
            this.navigateToEdit(quote);
        })
        .catch(error => {
            console.log('errr', error)
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error while creating record',
                    message: error,
                    variant: 'error',
                }),
            );
        });
    }
    navigateToEdit(quoteRecord) {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/lightning/r/SF_Quote__c/' + quoteRecord.id +'/edit'
            },
        });
    };
}