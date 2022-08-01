import { LightningElement, api, wire } from 'lwc';
import getRangeRecords from '@salesforce/apex/SF_QuantityRangeRecords.getRangeRecords';
import { CurrentPageReference } from 'lightning/navigation';

export default class SF_Quantity_Range extends LightningElement {
    recordId;
    rangeRecords = [];
    range = 0;
    quantityFrom = 0;
    quantityTo = 0;
    price = 0;
    error;
    //loading=true;

    // catch recordId using CurrentPageReference
    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
        if (currentPageReference) {
            console.log(currentPageReference);
            this.recordId = currentPageReference?.state?.recordId;
            console.log(this.recordId, ' recordId');
        }
    }
    // call Apex method to get records of SF_Quantity_Range__c 
    @wire(getRangeRecords, { pli: '$recordId' })
    wiredRanges(result) {
        if (!!result.data && Array.isArray(result.data)) {
            console.log(result.data, ' res data')
            this.rangeRecords = result.data;
            this.error = undefined;
            //this.loading = false;
        } else if (result.error) {
            this.error = result.error;
            this.rangeRecords = undefined;
        }
    }
    handleAdd(){
        const rangeIndex = this.rangeRecords.length+1;
        const newRange = {
            Range__c: rangeIndex,
            Quantity_From__c: this.quantityFrom,
            Quantity_To__c: this.quantityTo,
            Price__c: this.price
        }
        this.rangeRecords.push(newRange);
    }
    handleQuanityFromChange(event){
        this.quantityFrom = event.target.value;
    }
    handleQuanityToChange(event){
        this.quantityTo = event.target.value;
    }    
    handlePriceChange(event){
        this.price = event.target.value;
    }

    
}