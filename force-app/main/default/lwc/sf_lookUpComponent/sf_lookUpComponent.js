import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import fetchRecords from '@salesforce/apex/SF_LookUpController.fetchRecords';
import getProductPliPriceMap from '@salesforce/apex/SF_LookUpController.getProductPliPriceMap';
import insertQlis from '@salesforce/apex/SF_QliController.insertQlis';
import reprice from '@salesforce/apex/SF_ProductRulesService.reprice';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import 	addLabel from '@salesforce/label/c.addLabel';
import 	nameLabel from '@salesforce/label/c.nameLabel';
import 	priceLabel from '@salesforce/label/c.priceLabel';
import 	quantityLabel from '@salesforce/label/c.quantityLabel';
import 	getPriceListError from '@salesforce/label/c.getPriceListError';
import 	fetchingProductsErrorLabel from '@salesforce/label/c.fetchingProductsErrorLabel';
import 	getProductPliMapErrorLabel from '@salesforce/label/c.getProductPliMapErrorLabel';
import 	addProductsHeaderLabel from '@salesforce/label/c.addProductsHeaderLabel';
import 	totalLabel from '@salesforce/label/c.totalLabel';
import 	cancelLabel from '@salesforce/label/c.cancelLabel';
import 	qlisCreateError from '@salesforce/label/c.qlisCreateError';
import 	MarkLabel from '@salesforce/label/c.MarkLabel';
import AcceptQuote from '@salesforce/apex/SF_AcceptQuote.AcceptQuote';
import ACCEPT_QUOTE_BTN from '@salesforce/label/c.AcceptQuoteBtn';

const FIELDS = ['SF_Quote__c.SF_Price_List__c'];
 
export default class sf_lookUpController extends NavigationMixin(LightningElement) {
 
    @api objectName;
    @api fieldName;
    quoteId;
    @api iconName;
    @api label;
    @api placeholder;
    @api className;
    @api required = false;
    @track products = [];
    @track message;
    showSpinner = false;
    showInnerSpinner = false;
    @track showDropdown = false;
    priceListId = '';
    isModalOpen = false;
    @track renderedProducts = [];
    @track productsToAdd = {};
    showFinalPage = false;
    totalPrice = 0;
    @track dataTableProducts = [];
    @track data = [];
    fldsItemValues = [];
    showTable = false;
    customLabels = {ADD: addLabel, NAME: nameLabel, PRICE: priceLabel, QUANTITY: quantityLabel, GET_PRICE_LIST_ERROR: getPriceListError, FETCHING_PRODUCTS_ERROR: fetchingProductsErrorLabel, GET_PRODUCTS_PLI_ERROR: getProductPliMapErrorLabel, ADD_PRODUCTS_HEADER_TEXT: addProductsHeaderLabel, TOTAL: totalLabel, CANCEL: cancelLabel, QUOTE_LINE_ITEMS_CREATION_ERROR: qlisCreateError, MARK: MarkLabel};
    recordId;
    recordPageUrl;
    acceptQuote = ACCEPT_QUOTE_BTN;

    @wire(CurrentPageReference)
    getCurrentPageReference(currentPageReference) {
        if(currentPageReference) {
            this.recordId = currentPageReference.state.c__recordId;
            this.quoteId = currentPageReference.state.c__recordId;
        }
    }

    

    @wire(getRecord, { recordId: '$quoteId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (error) {
            if(!error.body.message) {
                this.showAlert('error', null, this.customLabels.GET_PRICE_LIST_ERROR, null);
            } else {
                this.showAlert('error', error.body.message, this.customLabels.GET_PRICE_LIST_ERROR, null);
            }
            
        } else if (data) {
           this.priceListId = data.fields.SF_Price_List__c.value;
           console.log(this.priceListId);
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

    navigateToReadonly(quoteId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/lightning/r/SF_Quote__c/' + quoteId +  '/view?c__dumm=1'
            }
        }).then(url => {
            window.open(url);
        });
    }; 
     /**
    * @author: Jubo M.
    * @description: This method takes care of filtering products on client side
    */   
    filterProducts(event) {
       const userInput = event.target.value.toUpperCase();
       if(userInput.length > 2) {
         this.renderedProducts = this.products.filter(product => product.name.toUpperCase().indexOf(userInput) > -1);
       } else if(userInput.length === 0) {
        this.renderedProducts = this.products.slice(0, 2);
       }
    }
 
    showRecords() {
        this.showDropdown = true;
    }

    /**
    * @author: Jubo M.
    * @description: This method fetches products frmo apex
    */   
    fetchData() {
        this.resetValues();
        this.showSpinner = true;
        this.message = '';
        fetchRecords({
            priceListId: this.priceListId
        })
        .then(res => {
            if(Array.isArray(res) && res.length > 0) {
                this.pliCurrency = res[0].SF_Price_List_Items__r[0].CurrencyIsoCode;
                res.forEach(fetchedProd => {
                   if(fetchedProd.Is_Bundle__c === true && fetchedProd.Stand_Alone__c === false && fetchedProd.Products__r && fetchedProd.Products__r.length > 0) {
                    fetchedProd.Products__r.forEach(optionProd => {
                        if(optionProd.Optional__c) {
                            optionProd['checked'] = false;
                            optionProd['disabled'] = false;
                        } else {
                            optionProd['checked'] = true;
                            optionProd['disabled'] = true;
                        }

                        optionProd['quantity'] = 1;
                    });

                    this.buildProducts({fetchedProductId: fetchedProd.Id, fetchedProductName: fetchedProd.Name, showOptionProducts: false, fetchedProdOptional: fetchedProd.Optional__c, price: 0, priceListItem: fetchedProd.SF_Price_List_Items__r[0].Id,optionProducts: fetchedProd.Products__r, standAlone: fetchedProd.Stand_Alone__c});
                   } else if(fetchedProd.Is_Bundle__c === true && fetchedProd.Stand_Alone__c === true){
                    this.buildProducts({fetchedProductId: fetchedProd.Id, fetchedProductName: fetchedProd.Name, showOptionProducts: false, fetchedProdOptional: fetchedProd.Optional__c, price: fetchedProd.SF_Price_List_Items__r[0].Base_Price__c, priceListItem: fetchedProd.SF_Price_List_Items__r[0].Id, optionProducts: fetchedProd.Products__r, standAlone: fetchedProd.Stand_Alone__c});
                   } else {
                    this.buildProducts({fetchedProductId: fetchedProd.Id, fetchedProductName: fetchedProd.Name, showOptionProducts: false, fetchedProdOptional: fetchedProd.Optional__c, price: 0, priceListItem: fetchedProd.SF_Price_List_Items__r[0].Id,optionProducts: fetchedProd.Products__r, standAlone: fetchedProd.Stand_Alone__c});
                   }
                });
                this.renderedProducts = this.products.slice(0, 2);
                this.isModalOpen = true;
            }
            this.showSpinner = false;
            this.assignPricesToOptionProducts();
        }).catch(error => {
            this.showAlert('error', null, this.customLabels.FETCHING_PRODUCTS_ERROR, null);
            this.showSpinner = false;
        })
    }

    /**
    * @author: Jubo M.
    * @description: This method takes care of building product objects and push it in products array
    */   
    buildProducts(productInfo) {
        let obj = {};
        obj['id'] = productInfo.fetchedProductId;
        obj['name'] = productInfo.fetchedProductName;
        obj['showOptionProducts'] = productInfo.showOptionProducts;
        obj['checked'] = false;
        obj['optionProducts'] = productInfo.optionProducts;
        obj['fetchedProdOptional'] = productInfo.fetchedProdOptional;
        obj['price'] = productInfo.price;
        obj['priceListItem'] = productInfo.priceListItem;
        obj['quantity'] = 1;
        obj['disabled'] = false;
        obj['standAlone'] = productInfo.standAlone;

        this.products.push(obj);
    }

    /**
    * @author: Jubo M.
    * @description: This method takes care of rendering option products 
    */   
    renderOptionProducts(e) {
        this.products.forEach(product => {
            if(e.target.getAttribute('data-key') === product.id && product.showOptionProducts === true) {
                product.showOptionProducts = false;
                product.checked = false;
            } else if(e.target.getAttribute('data-key') === product.id && product.showOptionProducts === false){
                product.standAlone ? product.showOptionProducts = false : product.showOptionProducts = true;
                product.checked = true;
            }
        });
    }

    /**
    * @author: Jubo M.
    * @description: This method takes care of adding/taking off the option product and re-calculate price of bundle product
    */   
    addOptionalProduct(e) {
        this.products.forEach(product => {
            if(product.standAlone === false) {
                product.optionProducts.forEach(optionalProd => {
                    if(e.target.getAttribute('data-key') === optionalProd.Id && optionalProd.checked === true) {
                        optionalProd.checked = false;
                        product.price = product.price - optionalProd.price;
                    } else if(e.target.getAttribute('data-key') === optionalProd.Id && optionalProd.checked === false){
                        optionalProd.checked = true;
                        product.price = product.price + optionalProd.price;
                    }
                });
            }
        });
    }

    /**
    * @author: Jubo M.
    * @description: This method takes care of assigning prices to option products
    */   
    assignPricesToOptionProducts() {
        const productIds = [];

        this.products.forEach(product => {
            if(product.standAlone === false) {
                product.optionProducts.forEach(op => {
                 productIds.push(op.Id);
                })
            }
        });

        getProductPliPriceMap({productIds: productIds, priceListId: this.priceListId}).then(res => {
            for (const productId in res) {
                this.products.forEach(p => {
                    console.log('p', p);
                    if(p.standAlone === false) {
                        p.optionProducts.forEach(op => {
                            if(op.Id === productId) {
                                op['price'] = res[productId].Base_Price__c;
                                op['priceListItem'] = res[productId].Id;
                            }
                        })
                    }
                })
            }

            this.products.forEach(bundleProduct => {
                if(bundleProduct.standAlone === false) {
                    let price = 0;
                    bundleProduct.optionProducts.forEach(opProd => {
                    if(opProd.Optional__c === false) {
                        price = price + parseFloat(opProd.price);
                    }
                })

                bundleProduct.price = price;
                }
            })
            
        }).catch(error => {
            if(!error.body.message) {
                this.showAlert('error', null, this.customLabels.GET_PRODUCTS_PLI_ERROR, null);
                this.showSpinner = false;
            } else {
                this.showAlert('error', error.body.message, this.customLabels.GET_PRODUCTS_PLI_ERROR, null);
                this.showSpinner = false;
            }
        })
    }

    /**
    * @author: Jubo M.
    * @description: This method takes care of adding product in popup table
    */   
    addProductsInTable(e) {
        console.log('@@@@@@products', this.products);
        this.products.forEach(product => {
                if(product.id === e.target.getAttribute('data-key') && product.checked === true) {
                    const productPrice = parseFloat(product.price);
                    this.dataTableProducts.push({id: product.id, name: product.name, price: productPrice, quantity: product.quantity, isBundle: true, priceListItem: product.priceListItem, price: product.price, standAlone: product.standAlone});
                    this.updateTotalPrice();
                    if(product.standAlone === false) {
                        product.optionProducts.forEach(optionalProd => {
                            if((optionalProd.checked === true && optionalProd.Optional__c === true) || (optionalProd.checked === true && optionalProd.Optional__c === false)) {
                                this.dataTableProducts.push({id: optionalProd.Id, name: optionalProd.Name, price: optionalProd.price, quantity: optionalProd.quantity, isBundle: false, quantity: optionalProd.quantity, priceListItem: optionalProd.priceListItem})
                                this.updateTotalPrice();
        
                            } else if(optionalProd.checked === false && optionalProd.Optional__c === false){
                                this.dataTableProducts.push({id: optionalProd.Id, name: optionalProd.Name, price: optionalProd.price, quantity: optionalProd.quantity, isBundle: false, priceListItem: optionalProd.priceListItem});
                                this.updateTotalPrice();
                            }
                        });
                    }
                }
        });
        
        this.data = this.dataTableProducts;
        this.showTable = true;
    }


    closeDropDown() {
        this.showDropdown = false;
    }

    closeModal() {
        this.isModalOpen = false;
        this.resetValues();
    }
    submitDetails() {
        this.isModalOpen = false;
    }
    /**
    * @author: Jubo M.
    * @description: This method resets values of class variables
    */   
    resetValues() {
        this.products = [];
        this.renderedProducts = [];
        this.productsToAdd = {};
        this.dataTableProducts = [];
        this.data = [];
        this.fldsItemValues = [];
        this.showDropdown = false;
        this.showTable = false;
        this.totalPrice = 0;
    }

    /**
    * @author: Jubo M.
    * @description: This method takes care of updating total price of products added in popup table
    */   
    updateTotalPrice() {
        this.totalPrice = 0;
        this.dataTableProducts.forEach(product => {
            this.totalPrice = this.totalPrice + (product.price * product.quantity);
        });
    }

    /**
    * @author: Jubo M.
    * @description: This method takes care of handling quantity change of products in popup
    */   
    handleQtyChange(e) {
        this.products.forEach(product => {
            if(product.id === e.target.getAttribute('data-key')) {
                product.quantity = e.target.value;
            } else {
                if(product.standAlone === false) {
                    product.optionProducts.forEach(op => {
                        if(op.Id === e.target.getAttribute('data-key')) {
                            op.quantity = e.target.value;
                        }
                    })
                }
            }
        })
    }

    /**
    * @author: Jubo M.
    * @description: This method takes care of inserting new product
    */   
    addProduct() {
        if(this.dataTableProducts.length > 0) {
            this.showInnerSpinner = true;
            this.productsToAdd = {};
            this.dataTableProducts.forEach(dtp => {
                console.log('dtp: ', dtp);

                if(dtp.isBundle === true && dtp.standAlone === false) {
                    console.log('started first if')
                    let obj = {};
                    obj['quantity'] = dtp.quantity.toString();
                    obj['priceListItem'] = dtp.priceListItem;
                    obj['hasOptionalProducts'] = 'true';
                    this.productsToAdd[dtp.id] = obj;
                } else if(dtp.isBundle === true && dtp.standAlone === true) {
                    console.log('started second if')
                    let obj = {};
                    obj['quantity'] = dtp.quantity.toString();
                    obj['priceListItem'] = dtp.priceListItem;
                    obj['hasOptionalProducts'] = 'standAlone';
                    this.productsToAdd[dtp.id] = obj;
                } else if(dtp.isBundle === false) {
                    console.log('started third if')
                    let obj = {};
                    obj['quantity'] = dtp.quantity.toString();
                    obj['priceListItem'] = dtp.priceListItem;
                    obj['hasOptionalProducts'] = 'false';
                    this.productsToAdd[dtp.id] = obj;
                }
            });

            console.log('products to add: ', this.productsToAdd);
     
            insertQlis({productIdQliInfoMap: this.productsToAdd, quoteId: this.quoteId}).then(res => {
                if(!!res && typeof(res) === 'string') {
                    this.showAlert('success', null, res, null);
                    this.showInnerSpinner = false;
                    this.isModalOpen = false;
                    this.products = [];
                    this.dataTableProducts = [];
                    this.productsToAdd = {};
                    this.data = [];

                    const addProductsEvent = new CustomEvent("addproductsevent", {
                        detail: null,
                        bubbles: true
                      });
                   
                    this.dispatchEvent(addProductsEvent);
                } else {
                    this.showAlert('error', null, this.customLabels.QUOTE_LINE_ITEMS_CREATION_ERROR, null);
                }
            }).catch(error => {
                if(!error.body.message) {
                    this.showAlert('error', null, this.customLabels.QUOTE_LINE_ITEMS_CREATION_ERROR, null);
                    this.showSpinner = false;
                } else {
                    this.showAlert('error', error.body.message, this.customLabels.QUOTE_LINE_ITEMS_CREATION_ERROR, null);
                    this.showSpinner = false;
                }
            });
        }
    }

    /**
    * @author: Jubo M.
    * @description: This method calls apex method which will conduct repricing
    */   
    doReprice() {
        this.showSpinner = true;
        reprice({quoteId: this.quoteId}).then(res => {
            console.log('@@@@@@@@@@@@@@@@reprice res: ', res);
            const repriceEvent = new CustomEvent("repriceevent", {
                detail: null,
                bubbles: true
              });
           
            this.dispatchEvent(repriceEvent);
            if(!!res && Array.isArray(res)) {
                console.log('@@@@entered inside if in repriceresponse');
                res.forEach(prodData => {
                    prodData.prodRuleData.forEach(prodRuleDataItem => {
                        this.showAlert(prodRuleDataItem.type, prodRuleDataItem.message, null, 'sticky');
                    })
                })

                this.showSpinner = false;
            }
        }).catch(err => {
            console.log('Error occured while trying to conduct repricing: ', err);
        })
    }

    /**
    * @author: Jubo M.
    * @description: This method takes care of showing toast events
    */   
    showAlert(type, message, additionalData, mode) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: additionalData,
                message : message,
                variant: type,
                mode: mode
            }),
        );
    }
}