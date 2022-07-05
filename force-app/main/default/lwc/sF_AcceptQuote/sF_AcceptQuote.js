import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import AcceptQuote from '@salesforce/apex/SF_AcceptQuote.AcceptQuote';
import ACCEPT_QUOTE_BTN from '@salesforce/label/c.AcceptQuoteBtn';

    // LWC to update quote status on button click 'Accept Quote'

export default class SF_AcceptQuote extends NavigationMixin(LightningElement) {

    recordId;
    recordPageUrl;
    acceptQuote = ACCEPT_QUOTE_BTN;
    
    // use wire method to catch recordId
    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
       if (currentPageReference) {
          this.recordId = currentPageReference.state.c__recordId;
       }
    }

    // call apex method which updates quote's status to 'Accepted'
    CallAcceptQuote(){
            if (!!this.recordId) {
            AcceptQuote({quoteId:this.recordId}).then(()=>{
                this.navigateToReadonly(this.recordId);
            })
        }
    }
    
    // after updating, navigate to quote detail page ---- record
    //navigateToReadonly(quoteId) {
        // this[NavigationMixin.Navigate]({
        //     type: 'standard__recordPage',
        //     attributes: {
        //         url: '/lightning/r/SF_Quote__c/' + quoteId + '/view'
        //     },
        // });
        // this[NavigationMixin.GenerateUrl]({
        //     type: 'standard__recordPage',
        //     attributes: {
        //         recordId: this.recordId,
        //         actionName: 'view',
        //     },
        // })
        navigateToReadonly(quoteId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: '/lightning/r/SF_Quote__c/' + quoteId +  '/view?c__dumm=1'                }
            }).then(url => {
                window.open(url);
            });
        }; 
    };