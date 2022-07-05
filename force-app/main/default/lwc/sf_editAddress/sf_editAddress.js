import { LightningElement, track, wire, api } from 'lwc';
import { updateRecord, getRecord, getFieldValue } from 'lightning/uiRecordApi';
import AccountId from '@salesforce/schema/Account.Id';
import BillingCountry from '@salesforce/schema/Account.Billing_Country__c';
import BillingPostalCode from '@salesforce/schema/Account.Billing_Postal_Code__c';
import BillingState from '@salesforce/schema/Account.Billing_State__c';
import BillingStreet from '@salesforce/schema/Account.Billing_Street__c';
import ShippingCountry from '@salesforce/schema/Account.Shipping_Country__c';
import ShippingPostalCode from '@salesforce/schema/Account.Postal_Code__c';
import ShippingState from '@salesforce/schema/Account.Shipping_State__c';
import ShippingStreet from '@salesforce/schema/Account.Shipping_Street__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUserInfo from '@salesforce/apex/UserManager.getUserInfo';
import editShipping from '@salesforce/label/c.Edit_Shipping_Label';
import editBilling from '@salesforce/label/c.Edit_Billing_Label';
import mapHelpText from '@salesforce/label/c.Map_Help_Text_Label';
import sysAdmin from '@salesforce/label/c.Sys_Admin_Label';
import salesManager from '@salesforce/label/c.Sales_Manager_Label';
import saveText from '@salesforce/label/c.Save_Label';
import cancelText from '@salesforce/label/c.Cancel_Label';
import addressTitleText from '@salesforce/label/c.Address_Title_Label';
import addressDescriptionText from '@salesforce/label/c.Adress_Descreption_Label';
import accountUpdateSuccessText from '@salesforce/label/c.Account_Update_Success_Label';
import accountUpdateErrorText from '@salesforce/label/c.Account_Update_Error';
import sfEditAddressRenderErrorText from '@salesforce/label/c.sfEditAddressRenderErrorLabel';
import accountLoadingErrorText from '@salesforce/label/c.Account_Loading_Error_Label';
import unknownErrorText from '@salesforce/label/c.Unknown_Error_Label';

const BUTTONLABELS = {shippingLabel: 'Edit Shipping Address', billingLabel: 'Edit Billing Address'};
const FIELDS = ['Account.Billing_Country__c', 'Account.Billing_Postal_Code__c', 'Account.Billing_State__c', 'Account.Billing_Street__c', 'Account.Shipping_Country__c', 'Account.Postal_Code__c', 'Account.Shipping_State__c', 'Account.Shipping_Street__c',];

export default class SF_changeAddress extends LightningElement {
    //Declaring Variables
    @track mapMarkers;
    zoomLevel = 10;
    listView = 'visible';
    @track address = {city: '', country: '', postalCode: '', province: '', street: ''};
    @api recordId;
    showCreateButtons = false;
    showMap = false;
    createButton = '';
    @track existingAaddresses = {};
    @track addressFields = {city: '', country: '', postalCode: '', state: '', street: ''};
    labels = {
        editShippingLabel: editShipping,
        editBillingLabel: editBilling,
        mapHelpTextLabel: mapHelpText,
        sysAdminLabel: sysAdmin,
        salesManagerLabel: salesManager,
        saveLabel: saveText,
        cancelLabel: cancelText,
        addressTitleLabel: addressTitleText,
        addressDescriptionLabel: addressDescriptionText,
        accountUpdateSuccessLabel: accountUpdateSuccessText,
        accountUpdateErrorLabel: accountUpdateErrorText,
        sfEditAddressRenderErrorLabel: sfEditAddressRenderErrorText,
        accountLoadingErrorLabel: accountLoadingErrorText,
        unknownErrorLabel: unknownErrorText
    }

    //Wiring current user's info
    @wire(getUserInfo, {}) 
    userData({ error, data }) {
        if(data) {
            if(data.Profile.Name === this.labels.sysAdminLabel || data.Profile.Name === this.labels.salesManagerLabel) {    
                this.showCreateButtons = true;
            }
        } else if(error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.labels.sfEditAddressRenderErrorLabel,
                    message: error.body.message,
                    variant: 'error'
                })
            );
        }
    }

    //Wiring Account records
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (error) {
            let message = this.labels.unknownErrorLabel;
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.labels.accountLoadingErrorLabel,
                    message,
                    variant: 'error',
                }),
            );
        } else if (data) {
            console.log('data: ', data.fields);
            this.existingAaddresses = {
                biliing: {
                    country: data.fields.Billing_Country__c.value,
                    postalCode: data.fields.Billing_Postal_Code__c.value,
                    state: data.fields.Billing_State__c.value,
                    street: data.fields.Billing_Street__c.value,
                },

                shipping: {
                    country: data.fields.Shipping_Country__c.value,
                    postalCode: data.fields.Postal_Code__c.value,
                    state: data.fields.Shipping_State__c.value,
                    street: data.fields.Shipping_Street__c.value,
                }
            }
        }
    }

    /**
    * This function is assigning user input to as property values in 'address' object 
    * @author Jubo M.
    */
    handleAddressChange(e) {
        if(!!e.target.city && !!e.target.country) {
            this.address = {city: e.target.city, country: e.target.country, postalCode: e.target.postalCode, province: e.target.province, street: e.target.street};
            this.searchAddress();
        } 
    }

    /**
    * This function changing marker location on map
    * @author Jubo M.
    */
    searchAddress() {
            this.mapMarkers = [
                {
                    location: {
                        City: this.address.city,
                        Country: this.address.country,
                        PostalCode: this.address.postalCode,
                        State: this.address.province,
                        Street: this.address.street
                    },
                    title: this.labels.addressTitleLabel,
                    description: this.labels.addressDescriptionLabel,
                    icon: 'standard:account'
                }
            ];
    }

    /**
    * This function is capturing wether user wants to edit billing or shipping address and calling another function
    * @author Jubo M.
    */
    createButtonHandler(e) {
        this.createButton = e.target.label;
        this.configureMap();
    }

    /**
    * This function is configuring map to render previous location - billing or shipping
    * @author Jubo M.
    */
    configureMap() {
        this.addressFields = this.createButton === BUTTONLABELS.billingLabel ? this.existingAaddresses.biliing : this.existingAaddresses.shipping;

        this.mapMarkers = [
            {
                location: {
                    City: '',
                    Country: this.addressFields.country,
                    PostalCode: this.addressFields.postalCode,
                    State: this.addressFields.state,
                    Street: this.addressFields.street
                },
                title: this.labels.addressTitleLabel,
                description: this.labels.addressDescriptionLabel,
                icon: 'standard:account'
            }
        ];
        this.hideCreateButtons();
    }
    
    /**
    * This function is saves new billing/shipping address in database
    * @author Jubo M.
    */
    saveHandler() {
        console.log(this.mapMarkers[0].location)
        const fields = {};

        fields[AccountId.fieldApiName] = this.recordId;
        this.createButton === BUTTONLABELS.billingLabel ? fields[BillingCountry.fieldApiName] = this.mapMarkers[0].location.Country : fields[ShippingCountry.fieldApiName] = this.mapMarkers[0].location.Country;

        this.createButton === BUTTONLABELS.billingLabel ? fields[BillingPostalCode.fieldApiName] = this.mapMarkers[0].location.PostalCode : fields[ShippingPostalCode.fieldApiName] = this.mapMarkers[0].location.PostalCode;

        this.createButton === BUTTONLABELS.billingLabel ? fields[BillingState.fieldApiName] = this.mapMarkers[0].location.State : fields[ShippingState.fieldApiName] = this.mapMarkers[0].location.State;

        this.createButton === BUTTONLABELS.billingLabel ? fields[BillingStreet.fieldApiName] = this.mapMarkers[0].location.Street : fields[ShippingStreet.fieldApiName] = this.mapMarkers[0].location.Street;
        
        const recordInput = {
            fields: fields
        };

        updateRecord(recordInput).then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: this.labels.accountUpdateSuccessLabel,
                    variant: 'success'
                })
            );
            this.showMap = false;
            this.showCreateButtons = true;
            }).catch(error => {
                console.log(error)
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.labels.accountUpdateErrorLabel + this.recordId,
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }

    /**
    * This function takes care of rendering 'Edit Billing Address' and 'Edit Shipping Address' buttons and hiding address fields and map
    * @author Jubo M.
    */
    cancelHandler() {
        this.showCreateButtons = true;
        this.showMap = false;
    }

    /**
    * This function takes care of hiding 'Edit Billing Address' and 'Edit Shipping Address' buttons and rendering address fields and map
    * @author Jubo M.
    */
    hideCreateButtons() {
        this.showCreateButtons = false;
        this.showMap = true;
    }
}