public class skedGridBuilder {
    
    public configuration config { get; set; }
    
    public gridModel initialize() {
        gridModel g = new GridModel();
        initializeCells(g);
        populateCellsData(g);
        return g;
    }
    
    /*********************************************************** Private methods ***********************************************************/
    private void initializeCells(gridModel g) {
        string timezoneSidId = this.config.timezoneSidId;

        Map<String, cellModel> mapCells = new Map<String, cellModel>();
        
        Date startDate = skedDateTimeUtils.getDateFromIsoString(this.config.startDate);
        Date endDate = skedDateTimeUtils.getDateFromIsoString(this.config.endDate);
        this.config.startTime = skedDateTimeUtils.getStartOfDate(startDate, timezoneSidId);
        this.config.endTime = skedDateTimeUtils.getEndOfDate(endDate, timezoneSidId);

        g.timezone = this.config.startTime.format('z', timezoneSidId);

        Integer daysNumber = 7;
        DateTime startTimeDt = this.config.startTime;
        for (Integer i = 0; i < daysNumber; i++) {
            String startDateStr = startTimeDt.format(skedDateTimeUtils.DATE_ISO_FORMAT, timezoneSidId);
            Integer startTimeInt = 0;
            while(startTimeInt < 2400) {
                cellModel cell = new cellModel();
                Integer hourInt = Integer.valueOf(startTimeInt / 100);
                Integer minuteInt = Math.mod(startTimeInt, 100);
                String hour = hourInt > 9 ? '' + hourInt : '0' + hourInt;
                String minute = minuteInt > 9 ? '' + minuteInt : '0' + minuteInt;
                cell.startTimeStr = startDateStr + 'T' + hour + ':' + minute + ':00Z';
                mapCells.put(cell.startTimeStr, cell);
                cell.startDate = startDateStr;
                cell.startTime = startTimeInt;

                Integer modular = Math.mod(startTimeInt + this.config.step, 100);
                if (modular >= 60) {
                    startTimeInt = (Integer.valueOf(startTimeInt / 100) + 1) * 100;
                } else {
                    startTimeInt += this.config.step;
                }

                cell.endTime = startTimeInt;
            }
            startTimeDt = skedDateTimeUtils.addDays(startTimeDt, 1, timezoneSidId);
        }

        List<cellModel> cells = mapCells.values();
        for (Integer i = cells.size() - 1; i > 0; i--) {
            cells[i].previousCell = cells[i - 1];
        }
        g.mapCells = mapCells;
    }

    private void populateCellsData(gridModel g) {
        Date startDate = skedDateTimeUtils.getDateFromIsoString(this.config.startDate);
        Date endDate = skedDateTimeUtils.getDateFromIsoString(this.config.endDate);

        Set<Date> inputDates = new Set<Date>();
        Date tempDate = startDate;
        while (tempDate <= endDate) {
            inputDates.add(tempDate);
            tempDate = tempDate.addDays(1);
        }

        skedAvailatorParams params = new skedAvailatorParams();
        params.timezoneSidId = this.config.timezoneSidId;
        params.startDate = startDate;
        params.endDate = endDate;
        params.resourceIds = this.config.resourceIds;
        params.tagIds = new Set<Id>();
        params.tagIds.addAll(this.config.job.tagIds);
        params.inputDates = inputDates;
        params.excludedJobIds = new Set<Id>();
        if (!string.isBlank(this.config.job.id)) {
            params.excludedJobIds.add(this.config.job.id);
        }

        skedResourceAvailability resourceAvailability = new skedResourceAvailability(params);
        Map<Id, skedResourceAvailabilityBase.resourceModel> mapResources = resourceAvailability.initializeResourceList();
        
        for (skedResourceAvailabilityBase.resourceModel resource : mapResources.values()) {
            populateCellData(g, resource);
        }
        g.cells = g.mapCells.values();
    }

    private void populateCellData(gridModel g, skedResourceAvailabilityBase.resourceModel resource) {
        Integer configTagsCount = this.config.job.tagIds == NULL ? 0 : this.config.job.tagIds.size();
        Integer resourceTagsCount = resource.tagIds == NULL ? 0 : resource.tagIds.size();
        if (configTagsCount != resourceTagsCount) {
            return;
        }

        Integer travelTimeFrom = 0, travelTimeTo = 0;
        if (resource.events.isEmpty()) {
            populateAvailableResources(g, this.config.startTime, this.config.endTime, travelTimeFrom, travelTimeTo, null);
            return;
        }

        Location jobLocation;
        skedModels.address jobAddress = this.config.job.address;
        if (jobAddress != NULL && jobAddress.geometry != NULL) {
            jobLocation = Location.newInstance(jobAddress.geometry.lat, jobAddress.geometry.lng);
        }

        Datetime endTime = this.config.endTime;
        if (resource.firstTagExpiry != NULL && resource.firstTagExpiry < this.config.endTime) {
            String endTimeStr = getCellKey(resource.firstTagExpiry, true);
            endTime = skedDateTimeUtils.getDateTimeFromIsoString(endTimeStr);
        }

        skedModels.event currentEvent = null;
        for (Integer i = 0; i < resource.events.size(); i++) {
            if (currentEvent == NULL) {
                currentEvent = resource.events[i];
            }

            if (i > 0 && i < resource.events.size() - 1 && currentEvent.finish >= resource.events[i].finish) {
                continue;
            } else {
                currentEvent = resource.events[i];
            }

            if (i == 0 && currentEvent.start > this.config.startTime) {
                if (jobLocation != NULL && currentEvent.geoLocation != NULL) {
                    travelTimeTo = skedUtils.getTravelTime(jobLocation, currentEvent.geoLocation);
                }
                populateAvailableResources(g, this.config.startTime, currentEvent.start, travelTimeFrom, travelTimeTo, endTime);
            } else if (i == resource.events.size() - 1 && currentEvent.finish < endTime) {
                if (jobLocation != NULL && currentEvent.geoLocation != NULL) {
                    travelTimeFrom = skedUtils.getTravelTime(currentEvent.geoLocation, jobLocation);
                }
                populateAvailableResources(g, currentEvent.finish, endTime, travelTimeFrom, travelTimeTo, endTime);
            } else {
                if (i < resource.events.size() - 1) {
                    skedModels.event nextEvent = resource.events[i + 1];

                    if (jobLocation != NULL) {
                        if (currentEvent.geoLocation != NULL) {
                            travelTimeFrom = skedUtils.getTravelTime(currentEvent.geoLocation, jobLocation);
                        }
                        if (nextEvent.geoLocation != NULL) {
                            travelTimeTo = skedUtils.getTravelTime(jobLocation, nextEvent.geoLocation);
                        }
                    }
                    populateAvailableResources(g, currentEvent.finish, nextEvent.start, travelTimeFrom, travelTimeTo, endTime);
                }
            }

            if (currentEvent.start >= endTime) {
                break;
            }
        }
    }

    private void populateAvailableResources(gridModel g, DateTime availableBlockStart, DateTime availableBlockEnd, Integer travelTimeFrom, Integer travelTimeTo, DateTime tagExpiry) { 
        if (availableBlockStart < System.now()) {
            return;
        }
        if (availableBlockStart < availableBlockEnd) {
            Datetime firstSlotStart, lastSlotStart;
            String firstSlotStartStr, lastSlotStartStr;

            if (tagExpiry != NULL && tagExpiry < availableBlockEnd) {
                availableBlockEnd = tagExpiry;
            }
            
            firstSlotStart = skedDateTimeUtils.addMinutes(availableBlockStart, travelTimeFrom, this.config.timezoneSidId);
            firstSlotStartStr = getCellKey(firstSlotStart, true);

            lastSlotStart = skedDateTimeUtils.addMinutes(availableBlockEnd, - (travelTimeTo + this.config.job.duration), this.config.timezoneSidId);
            lastSlotStartStr = getCellKey(lastSlotStart, false);

            cellModel currentCell = g.mapCells.get(lastSlotStartStr);
            if (currentCell == NULL) {
                return;
            }
            DateTime startTime = skedDateTimeUtils.getDateTimeFromIsoString(currentCell.startTimeStr);
            firstSlotStart = skedDateTimeUtils.getDateTimeFromIsoString(firstSlotStartStr);
            while (currentCell != NULL && startTime >= firstSlotStart) {
                currentCell.noOfAvailable += 1;
                currentCell = currentCell.previousCell;
                startTime = skedDateTimeUtils.getDateTimeFromIsoString(currentCell.startTimeStr);
            }
        }
    }

    private String getCellKey(DateTime dt, boolean isRoundUp) {
        DateTime tempDt;
        Integer minute = Integer.valueOf(dt.format('mm', this.config.timezoneSidId));
        Integer mod = Math.mod(minute, this.config.step);
        if (mod == 0) {
            tempDt = dt;
        } else {
            integer addedMinute;
            if (isRoundUp == true) {
                addedMinute = this.config.step - mod;
            }
            else {
                addedMinute = (-1) * mod;
            }
            tempDt = skedDateTimeUtils.addMinutes(dt, addedMinute, this.config.timezoneSidId);
        }
        return tempDt.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', this.config.timezoneSidId);
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    public class gridModel {
        public string timezone {get;set;}
        public List<cellModel> cells {get; set;}
        public transient Map<String, cellModel> mapCells {get; set;}
    }
    
    public class cellModel {
        public string startDate {get;set;}
        public integer startTime {get; set;}
        public integer endTime {get; set;}
        public integer noOfAvailable {get; set;}
        
        public transient String startTimeStr {get; set;}
        public transient cellModel previousCell {get; set;}
        
        public cellModel() {
            this.noOfAvailable = 0;
        }
    }
    
    public virtual class configuration {
        public skedModels.job job {get;set;}

        public string timezoneSidId {get;set;}
        public string startDate {get;set;}
        public string endDate {get;set;}
        public Set<Id> resourceIds {get; set;}
        public integer step {get; set;}
        // not define
        public transient Datetime startTime {get; set;}
        public transient Datetime endTime {get; set;}
    }
}