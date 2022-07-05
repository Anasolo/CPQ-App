import { LightningElement, track, api, wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import getQlis from '@salesforce/apex/SF_QliController.getQlis';

export default class Sf_addProducts extends LightningElement {
    @track qlis = [];
    @track columns = [
        {label: 'Subtotal', fieldName: 'Unit_Price__c', type: 'currency'},
        {label: 'Total Price', fieldName: 'List_Price__c', type: 'currency'},
        {label: 'Quantity', fieldName: 'Quantity__c', type: 'number'}
    ];
    showDataTable = false;
    @api recordId;
    @wire(getQlis, { quoteId: '$recordId' })
    wiredQlis({ error, data }) {
        if (data) {
            console.log(data);
            this.qlis = data;
            this.showDataTable = true;
        } else if (error) {
            console.log(error);
        }
    }
}