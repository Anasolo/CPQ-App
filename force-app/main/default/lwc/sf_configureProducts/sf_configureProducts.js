import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getQlis from '@salesforce/apex/SF_QliController.getQlis';
import getFieldsLabelsMap from '@salesforce/apex/SF_QliController.getFieldsLabelsMap';
import getEditableFields from '@salesforce/apex/SF_QliController.getEditableFields';
import updateQlis from '@salesforce/apex/SF_QliController.updateQlis';
import cloneQli from '@salesforce/apex/SF_QliController.cloneQli';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import 	showOptionButtonsLabel from '@salesforce/label/c.showOptionButtonsLabel';
import 	editButtonLabel from '@salesforce/label/c.editButtonLabel';
import 	getFieldsMapErrorLabel from '@salesforce/label/c.getFieldsMapErrorLabel';
import 	quoteLineItemsUpdatedSuccessLabel from '@salesforce/label/c.quoteLineItemsUpdatedSuccessLabel';
import 	quoteLineItemsUpdateErrorLabel from '@salesforce/label/c.quoteLineItemsUpdateErrorLabel';
import 	getQlisErrorLabel from '@salesforce/label/c.getQlisErrorLabel';
import 	Save_Label from '@salesforce/label/c.Save_Label';
import 	Cancel_Label from '@salesforce/label/c.Cancel_Label';
import 	editIconNameLabel from '@salesforce/label/c.editIconNameLabel';
import 	undoIconNameLabel from '@salesforce/label/c.undoIconNameLabel';
import 	dashIconNameLabel from '@salesforce/label/c.dashIconNameLabel';
import 	addIconNameLabel from '@salesforce/label/c.addIconNameLabel';
import actionsButtonLabel from '@salesforce/label/c.actionsButtonLabel';
import cloneButtonLabel from '@salesforce/label/c.cloneButtonLabel';


const dataTypes = {DOUBLE: 'number', CURRENCY: 'currency', STRING: 'text'};

export default class Sf_addProducts extends LightningElement {
    staticLabels = {ADD: showOptionButtonsLabel, ACTIONS: actionsButtonLabel, SAVE_BUTTON_LABEL: Save_Label, CANCEL_BUTTON_LABEL: Cancel_Label, DASH_ICON: dashIconNameLabel, ADD_ICON: addIconNameLabel, EDIT_ICON: editIconNameLabel, UNDO_ICON: undoIconNameLabel, CLONE_BUNDLE_PRODUCT: cloneButtonLabel};
    @track qlis = [];
    @track columns = [];
    quoteId;
    @track currentPageReference;
    showDataTable = false;
    @track editableFields = [];
    showSpinner = false;
    @track fieldLabels = [showOptionButtonsLabel];
    @track optionQlisFieldLabels = [];
    @track fieldsToDisplay = [];
    @track tableData = [];
    showSaveCancelButtons = false;
    @track qlisToUpdate = [];
    currencyIsoCode = '';
    wiredFieldsMapRes = {};


    @wire(CurrentPageReference)
    getCurrentPageReference(currentPageReference) {
        if(currentPageReference) {
            this.quoteId = currentPageReference.state.c__recordId;
        }
    }

    @wire(getEditableFields)
    wiiredFields({ error, data }) {
        if (Array.isArray(data) && data.length > 0) {
            data.forEach(fieldName => {
                this.editableFields.push(fieldName.trim());
            });

        } else if (error) {
            console.log(error);
        }
    }

    @wire(getFieldsLabelsMap)
    wiredFieldsMap(result) {
        this.wiredFieldsMapRes = result;
        if (result.data) {
            this.getQliRecords(result.data);
        } else if (result.error) {
            this.showAlert('error', getFieldsMapErrorLabel, null);
        }
    }
    /**
    * @author: Jubo M.
    * @description: This method takes care of getting Quote Line Items of the Quote of which record id is in url currently
    */   
    getQliRecords(fieldNamesLabels) {
        if(!!this.quoteId) {
            const fieldNames = [];

            this.fieldLabels = [showOptionButtonsLabel];
            this.optionQlisFieldLabels = [];
            this.fieldsToDisplay = [];
            this.tableData = [];
            this.qlisToUpdate = [];

            for (const fieldName in fieldNamesLabels) {
                fieldNames.push(fieldName);
            }

            getQlis({quoteId: this.quoteId, fieldsToQUery: fieldNames}).then(res => {
                console.log('res', res);
                if(Array.isArray(res) && res.length > 0) {
                    this.currencyIsoCode = res[0].bundleQli.CurrencyIsoCode;
                    console.log(res);
                    this.qlis = res;
                    let fieldType = '';
                    let editable = false;
                    fieldNames.forEach(fieldName => {
                        this.fieldLabels.push(fieldNamesLabels[fieldName].label);
                        this.optionQlisFieldLabels.push(fieldNamesLabels[fieldName].label);
                        fieldType = fieldNamesLabels[fieldName].datatype;
                        editable = this.editableFields.includes(fieldName);
                    });

                    this.optionQlisFieldLabels.push(this.staticLabels.ACTIONS);

                    this.fieldLabels.push(this.staticLabels.ACTIONS);

                    res.forEach(qli => {
                        let qliObj = {};
                        qliObj['id'] = qli.bundleQli.Id;
                        qliObj['data'] = [];
                        qliObj.data.push({fieldApiName: this.staticLabels.ADD, displayValue: this.staticLabels.ADD, editable: false, disabled: true, isInput: false, inputType: null, isBundle: true, buttonIsAdd: true, isCloneButton: false, isEditIcon: false});
                        qliObj['optionQlis'] = [];
                        qliObj['showOptionQlis'] = false;
                        qliObj['Product__c'] = qli.bundleQli.Product__c;
                        qliObj['Product__r'] = qli.bundleQli.Product__r;
                        qliObj['SF_Price_List_Item__c'] = qli.bundleQli.SF_Price_List_Item__c;

                        fieldNames.forEach(fieldName => {
                            let innerObj = {};

                            console.log('type', fieldName, fieldNamesLabels[fieldName].datatype, dataTypes[fieldNamesLabels[fieldName].datatype]);
                            fieldType = dataTypes[fieldNamesLabels[fieldName].datatype];
                            innerObj['fieldApiName'] = fieldName;
                            let priceField = 0;
                            if(fieldName === 'List_Price__c' || fieldName === 'Unit_Price__c' || fieldName === 'Total_Price__c') {
                                if(qli.bundleQli.Product__r.Stand_Alone__c) {
                                    priceField = qli.bundleQli[fieldName];
                                } else {
                                    qli.optionQlis.forEach(opQli => {
                                        priceField = priceField + opQli[fieldName];
                                    });
                                }

                                qli.bundleQli[fieldName] = priceField;
                            }
                            innerObj['displayValue'] = qli.bundleQli[fieldName];
                            innerObj['disabled'] = true;
                            innerObj['isInput'] = true;
                            innerObj['isBundle'] = true;
                            innerObj['fieldType'] = fieldType;
                            innerObj['buttonIsAdd'] = false;
                            innerObj['isCloneButton'] = false;
                            innerObj['isEditIcon'] = false;
                            fieldNamesLabels[fieldName].datatype === 'CURRENCY' ? innerObj['isCurrencyType'] = true : innerObj['isCurrencyType'] = false;
                            fieldName === 'Quantity__c' ? innerObj['editable'] = true : innerObj['editable'] = false;
                            (fieldType === dataTypes.DOUBLE || fieldType === dataTypes.CURRENCY) ? innerObj['inputType'] = 'number' : innerObj['inputType'] = 'text';
                            qliObj.data.push(innerObj);
                        });

                        qliObj.data.push({fieldApiName: this.staticLabels.ACTIONS, displayValue: this.staticLabels.ACTIONS, disabled: true, isInput: false, editable: false, inputType: null, isBundle: true, buttonIsAdd: false, isCloneButton: false, isEditIcon: true});

                        qli.optionQlis.forEach(opQli => {
                            let opQliObj = {};
                            opQliObj['id'] = opQli.Id;
                            opQliObj['data'] = [];
                            opQliObj['Product__c'] = opQli.Product__c;
                            opQliObj['Product__r'] = opQli.Product__r;
                            opQliObj['SF_Price_List_Item__c'] = opQli.SF_Price_List_Item__c;
                            console.log('opQliObj1: ', opQliObj);

                            fieldNames.forEach(fieldName => {
                                let opQliInnerObj = {};
                                fieldType = dataTypes[fieldNamesLabels[fieldName].datatype];
                                opQliInnerObj['fieldApiName'] = fieldName;
                                opQliInnerObj['displayValue'] = opQli[fieldName];
                                opQliInnerObj['disabled'] = true;
                                opQliInnerObj['isInput'] = true;
                                opQliInnerObj['isBundle'] = false;
                                opQliInnerObj['fieldType'] = fieldType;
                                opQliInnerObj['buttonIsAdd'] = false;
                                fieldNamesLabels[fieldName].datatype === 'CURRENCY' ? opQliInnerObj['isCurrencyType'] = true : opQliInnerObj['isCurrencyType'] = false;
                                fieldName === 'Quantity__c' ? opQliInnerObj['editable'] = true : opQliInnerObj['editable'] = false;
                                (fieldType === dataTypes.DOUBLE || fieldType === dataTypes.CURRENCY) ? opQliInnerObj['inputType'] = 'number' : opQliInnerObj['inputType'] = 'text';
                                opQliObj.data.push(opQliInnerObj);
                            });

                            opQliObj.data.push({fieldApiName: this.staticLabels.ACTIONS, displayValue: this.staticLabels.ACTIONS, disabled: true, isInput: false, editable: false, inputType: null, isBundle: false, buttonIsAdd: false});
                            console.log('opQliObj2: ', opQliObj);
                            qliObj.optionQlis.push(opQliObj);
                        })
                        this.tableData.push(qliObj);
                    });

                    this.showDataTable = true;
                    this.showSpinner = false;
                } else if(Array.isArray(res) && res.length < 1){
                    console.log('entered here')
                    this.showSpinner = false;
                }
            }).catch(err => {
                console.log('error', err)
                this.showAlert('error', getQlisErrorLabel, err.body.message);
            })
        }
    }

    /**
    * @author: Jubo M.
    * @description: This method takes care of udpdating Quote Line Items records
    */   
    updateQliRecords() {
        this.showSpinner = true;
        this.tableData.forEach(td => {
            td.data.forEach(fldData => {
                if(fldData.disabled === false) {
                    this.qlisToUpdate.push({id: td.id, fieldToUpdate: fldData.fieldApiName, newValue: fldData.displayValue.toString(), standAlone: true});
                }
            });

            td.optionQlis.forEach(opQli => {
                opQli.data.forEach(fldData => {
                    if(fldData.disabled === false) {
                        this.qlisToUpdate.push({id: opQli.id, fieldToUpdate: fldData.fieldApiName, newValue: fldData.displayValue.toString(), standAlone: false});
                    }
                });
            })
        })
        updateQlis({qlis: this.qlisToUpdate}).then(res => {
            if(typeof(res) === 'string') {
               this.showAlert('success', null, quoteLineItemsUpdatedSuccessLabel);
               this.getQliRecords(this.wiredFieldsMapRes.data);
               this.showSaveCancelButtons = false;
               this.showSpinner = false;
            }
        }).catch(error => {
            this.showSpinner = false;
            this.showAlert('error', quoteLineItemsUpdateErrorLabel, null);
        })
    }

    /**
    * @author: Jubo M.
    * @description: This method takes care of handling the input change of end user
    */   
    handleInputChange(e) {
        if(e.target.dataset.isBundle === 'true') {
            this.tableData.forEach(td => {
                console.log(td.id, e.target.getAttribute('data-key'));
                if(td.id === e.target.getAttribute('data-key')) {
                    td.data.forEach(fldData => {
                        if(fldData.fieldApiName === e.target.dataset.fieldApiName) {
                            fldData.displayValue = e.target.value;
                        }
                    })
                 }
            })
        }
         else {
            this.tableData.forEach(td => {
                td.optionQlis.forEach(opQli => {
                    if(opQli.id === e.target.getAttribute('data-key')) {
                        opQli.data.forEach(fldData => {
                            if(fldData.fieldApiName === e.target.dataset.fieldApiName) {
                                fldData.displayValue = e.target.value;
                            }
                        })
                    }
                })
            })
        }
        this.showSaveCancelButtons = true;
    }

    refreshComponent(event){
        eval("$A.get('e.force:refreshView').fire();");
    }
    /**
    * @author: Jubo M.
    * @description: This method takes care of shwoing toast events
    */   
    showAlert(type, message, additionalData) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: additionalData,
                message : message,
                variant: type,
            }),
        );
    }

    /**
    * @author: Jubo M.
    * @description: This method takes care of showing/hdiing option products
    */   
    handleOptionsVisibility(e) {
        console.log('table data: ', this.tableData);
        if(e.target.dataset.buttonLabel === this.staticLabels.ADD) {
            this.tableData.forEach(td => {
                if(td.id === e.target.getAttribute('data-key')) {
                    td.showOptionQlis = !td.showOptionQlis;
                    e.target.iconName = e.target.iconName ===  this.staticLabels.ADD_ICON ? this.staticLabels.DASH_ICON : this.staticLabels.ADD_ICON;
                }
            })
        } else if(e.target.dataset.buttonLabel === this.staticLabels.ACTIONS && e.target.iconName !== this.staticLabels.UNDO_ICON) {
                if(e.target.dataset.isBundle === 'true') {
                    this.tableData.forEach(td => {
                        if(td.id === e.target.getAttribute('data-key')) {
                            td.data.forEach(fldData => {
                                if(fldData.editable) {
                                    fldData.disabled = false;
                                }
                            })
                         }
                    })
                } else {
                    this.tableData.forEach(td => {
                        td.optionQlis.forEach(opQli => {
                            if(opQli.id === e.target.getAttribute('data-key')) {
                                opQli.data.forEach(fldData => {
                                    if(fldData.editable) {
                                        fldData.disabled = false;
                                    }
                                })
                            }
                        })
                    })
                }
                e.target.iconName = this.staticLabels.UNDO_ICON;
            
        } else if(e.target.dataset.buttonLabel === this.staticLabels.ACTIONS && e.target.iconName === this.staticLabels.UNDO_ICON) {
            if(e.target.dataset.isBundle === 'true') {
                this.tableData.forEach(td => {
                    if(td.id === e.target.getAttribute('data-key')) {
                        td.data.forEach(fldData => {
                            if(fldData.editable) {
                                fldData.disabled = true;
                            }
                        })
                     }
                });

                this.refreshComponent();
            } else {
                this.tableData.forEach(td => {
                    td.optionQlis.forEach(opQli => {
                        if(opQli.id === e.target.getAttribute('data-key')) {
                            opQli.data.forEach(fldData => {
                                if(fldData.editable) {
                                    fldData.disabled = true;
                                    e.target.iconName = this.staticLabels.EDIT_ICON;
                                }
                            })
                        }
                    })
                })
            }
            this.showSaveCancelButtons = false;
        }
    }

    /**
    * @author: Jubo M.
    * @description: This method takes care of refreshing rendered Quote Line Items after receiving the event from child component: sf_lookupComponent
    */   
    handleAddproductsFromLookup() {
        this.getQliRecords(this.wiredFieldsMapRes.data);
    }

    cloneBundleQli(e) {
        this.showSpinner = true;
        let bundleQli = {};
        let opQlis = [];
        this.tableData.forEach(td => {
            if(td.id === e.target.getAttribute('data-key')) {
                td.data.shift();
                const fldDataToPass = td.data.filter(el => td.data.indexOf(el) !== 0 && td.data.indexOf(el) !== td.data.length - 1);
                bundleQli['Product__c'] = td.Product__c;
                bundleQli['SF_Price_List_Item__c'] = td.SF_Price_List_Item__c;
                bundleQli['SF_Quote__c'] = this.quoteId;
                
                fldDataToPass.forEach(dataItem => {
                        bundleQli[dataItem.fieldApiName] = dataItem.displayValue.toString();
                });
                
                if(td.Product__r.Stand_Alone__c === false) {
                    td.optionQlis.forEach(opQli => {
                        const opFldDataToPass = opQli.data.filter(el => opQli.data.indexOf(el) !== 0 && opQli.data.indexOf(el) !== opQli.data.length - 1);
                        let obj = {};
                        obj['Product__c'] = opQli.Product__c;
                        obj['SF_Price_List_Item__c'] = opQli.SF_Price_List_Item__c;
                        obj['SF_Quote__c'] = this.quoteId;
                        opFldDataToPass.forEach(dataItem => {
                            obj[dataItem.fieldApiName] = dataItem.displayValue.toString();
                        });
                        opQlis.push(obj);
                    })
                }
            }
        });

        console.log('bundleQli@@@@@@@@: ', bundleQli, 'opQlis@@@@@@@@@@: ', opQlis);

        cloneQli({bundleQliMap: bundleQli, opQliMap: opQlis }).then(res => {
            if(res && typeof res === 'string') {
                this.showAlert('success', res, null);
                this.getQliRecords(this.wiredFieldsMapRes.data);
                this.showSpinner = false;
            }
        })
    }
}