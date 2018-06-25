public virtual class skedTravelTimeService {
    
    protected integer maxOrigins = 25;
    
    protected Map<string, skedModels.journey> mapJourney {get;set;}
    
    public skedTravelTimeService(List<skedModels.geometry> origins, List<skedModels.geometry> destinations) {
        List<distanceMatrixRequest> requests = getRequestList(origins, destinations);
        initialize(requests);
    }
    
    public virtual skedModels.journey getJourney(Location fromLoc, Location toLoc) {
        string originkey = fromLoc.getLatitude() + ',' + fromLoc.getLongitude();
        string destinationkey = toLoc.getLatitude() + ',' + toLoc.getLongitude();
        string key = originkey + '|' + destinationkey;
        return mapJourney.get(key);
    }
    
    public virtual skedModels.journey getJourney(decimal fromLat, decimal fromLng, decimal toLat, decimal toLng) {
        string originkey = fromLat + ',' + fromLng;
        string destinationkey = toLat + ',' + toLng;
        string key = originkey + '|' + destinationkey;
        return mapJourney.get(key);
    }
    
    protected void initialize(List<distanceMatrixRequest> requests) {
        //process matrix distance request
        this.mapJourney = new Map<string, skedModels.journey>();

		system.debug('#requests#' + requests.size());
        
        for (distanceMatrixRequest request : requests) {
            List<skedModels.geometry> originList = new List<skedModels.geometry>();
            originList.addAll(request.mapOrigin.values());
            
            List<skedModels.geometry> destinationList = new List<skedModels.geometry>();
            destinationList.addAll(request.mapDestination.values());
            
            skedSkeduloApiData.distanceMatrixResult matrixResult = skedSkeduloApiManager.calculateDistanceMatrix(originList, destinationList);
            if (matrixResult.success == true && matrixResult.data != NULL) {
                integer minDistance;
                for (integer i = 0; i < matrixResult.data.matrix.size(); i++) {
                    List<skedSkeduloApiData.Element> row = matrixResult.data.matrix.get(i);
                    for (integer j = 0; j < row.size(); j++) {
                        skedSkeduloApiData.Element element = row.get(j);
                        
                        skedModels.geometry originGeometry = originList.get(i);
                        string originKey = originGeometry.lat + ',' + originGeometry.lng;
                        
                        skedModels.geometry destinationGeometry = destinationList.get(j);
                        string destinationKey = destinationGeometry.lat + ',' + destinationGeometry.lng;
                        
                        skedModels.journey journey = new skedModels.journey();
                        journey.origin = originGeometry;
                        journey.destination = destinationGeometry;
                        if (element.distance != NULL) {
                            journey.distance = element.distance.distanceInMeters;
                        }
                        if (element.duration != NULL) {
                            journey.travelTime = element.duration.durationInSeconds;
                        }
                        journey.status = element.status;
                        
                        this.mapJourney.put(originKey + '|' + destinationKey, journey);
                    }
                }
            }
            else {
                //TODO: need to handle error, however, still not know how to force skedulo geoservices to throw error
                system.debug('#mapOrigin#' + request.mapOrigin.size());
                system.debug('#mapDestination#' + request.mapDestination.size());
                system.debug('#matrixResult#' + matrixResult);
            }
        } 
    }
    
    protected List<distanceMatrixRequest> getRequestList(List<skedModels.geometry> origins, List<skedModels.geometry> destinations) {
        List<distanceMatrixRequest> result = new List<distanceMatrixRequest>();
        
        integer noOfOriginSets = integer.valueOf(Math.ceil(decimal.valueOf(origins.size()) / maxOrigins));
        integer noOfDestinationSets = integer.valueOf(Math.ceil(decimal.valueOf(destinations.size()) / maxOrigins));
        
        for (integer i = 0; i < noOfOriginSets; i++) {
            integer originFirstIdx = maxOrigins * i;
            integer originLastIdx = originFirstIdx + (maxOrigins - 1);
            originLastIdx = originLastIdx > (origins.size() - 1) ? origins.size() - 1 : originLastIdx;

            Map<string, skedModels.geometry> mapOrigin = new Map<string, skedModels.geometry>();
            for (integer j = originFirstIdx; j <= originLastIdx; j++) {
                skedModels.geometry originGeometry = origins.get(j);
                mapOrigin.put(originGeometry.lat + ',' + originGeometry.lng, originGeometry);
            }
            
            for (integer m = 0; m < noOfDestinationSets; m++) {
                integer destinationFirstIdx = maxOrigins * m;
                integer destinationLastIdx = destinationFirstIdx + (maxOrigins - 1);
                destinationLastIdx = destinationLastIdx > (destinations.size() - 1) ? destinations.size() - 1 : destinationLastIdx;
                
                Map<string, skedModels.geometry> mapDestination = new Map<string, skedModels.geometry>();
                for (integer n = destinationFirstIdx; n <= destinationLastIdx; n++) {
                    skedModels.geometry destinationGeometry = destinations.get(n);
                    mapDestination.put(destinationGeometry.lat + ',' + destinationGeometry.lng, destinationGeometry);
                }
                
                distanceMatrixRequest request = new distanceMatrixRequest();
                request.mapOrigin = mapOrigin;
                request.mapDestination = mapDestination;
                result.add(request);
            }
        }
        
        return result;
    }
    
    /*************************************************Nested classes*******************************************************/
    public class distanceMatrixRequest {
        public Map<string, skedModels.geometry> mapOrigin {get;set;}
        public Map<string, skedModels.geometry> mapDestination {get;set;}
    }

}