import { LightningElement, track } from 'lwc';

export default class SF_changeAddress extends LightningElement {
    @track mapMarkers;
    zoomLevel = 10;
    listView = 'visible';

    connectedCallback() {
        this.mapMarkers = [
            {
                location: {
                    City: 'Ajmer',
                    Country: 'India',
                    PostalCode: '305001',
                    State: 'RJ',
                    Street: 'Ajay Nagar'
                },
                title: 'Salesforce bolt',
                description: 'I am here',
                icon: 'standard: account'
            }
        ];
    }
}