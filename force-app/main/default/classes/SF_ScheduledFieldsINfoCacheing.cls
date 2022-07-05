global class scheduledMerge implements Schedulable {
    global List<FieldsConfig__mdt> execute(SchedulableContext SC) {
        List<FieldsConfig__mdt> cachedFieldsInfo = (List<FieldsConfig__mdt>)Cache.Org.get('local.ConifgProductsFielldsInfoPart.fieldsInfo');

        if(cachedFieldsInfo == null || isEmpty(cachedFieldsInfo)) {
            SF_PlatformCacheData.refreshConfigProductsFieldsData();
        }

        return cachedFieldsInfo;
    }
 }