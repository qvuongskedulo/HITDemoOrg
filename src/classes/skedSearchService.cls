global class skedSearchService {
    public list<skedModels.contact> searchContact(searchOptionModel searchModel) {
        string searchLike = ' % ' + searchModel.textSearch + ' % ';
        list<Contact> entities = [SELECT Id, Name, AccountId, Birthdate, Email, FirstName, LastName, Phone,
                                                MailingCity, MailingCountry, MailingPostalCode, MailingState, MailingStreet,
                                                MailingLatitude, MailingLongitude
                                        FROM Contact
                                        WHERE Name like :searchLike];
        list<skedModels.contact> result = new list<skedModels.contact>();

        for (contact entity : entities) {
            skedModels.contact model = (skedModels.contact)skedAutoMapper.instance.mapTo(entity, skedModels.contact.class);
            model.address = new skedModels.address();
            model.address.fullAddress = skedUtils.combineAddress(entity.MailingStreet, entity.MailingCity, entity.MailingState, entity.MailingPostalCode, entity.MailingCountry);
            model.address.geometry = new skedModels.geometry(entity.MailingLatitude, entity.MailingLongitude);

            result.add(model);
        }

        return result;
    }

    global virtual class searchOptionModel {
        public string textSearch {get; set;}    
    }
}