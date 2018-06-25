global class skedSetting {

    private skedAdminSetting adminSetting;
    private skedRacSetting racSetting;
    private skedPacSetting pacSetting;
    private skedRmcSetting rmcSetting;
    private skedBookingGridSetting bgSetting;

    public skedAdminSetting Admin {
        get {
            if (adminSetting == null) {
                adminSetting = new skedAdminSetting();
            }
            return adminSetting;
        }
    }

    public skedRacSetting RAC {
        get {
            if (racSetting == null) {
                racSetting = new skedRacSetting();
            }
            return racSetting;
        }
    }

    public skedPacSetting PAC {
        get {
            if (pacSetting == null) {
                pacSetting = new skedPacSetting();
            }
            return pacSetting;
        }
    }

    public skedRmcSetting RMC {
        get {
            if (rmcSetting == null) {
                rmcSetting = new skedRmcSetting();
            }
            return rmcSetting;
        }
    }

    public skedBookingGridSetting BG {
        get {
            if (bgSetting == null) {
                bgSetting = new skedBookingGridSetting();
            }
            return bgSetting;
        }
    }

    /*********************************************************** Singleton stuffs ***********************************************************/
    private static skedSetting mInstance = null;

    public static skedSetting instance {
        get {
            if (mInstance == null) {
                mInstance = new skedSetting();
            }
            return mInstance;
        }
    }

    /*********************************************************** Private constructor ***********************************************************/
    private skedSetting() {}

    /*********************************************************** Nested Classes ***********************************************************/
    public class skedAdminSetting {
        public integer velocity {get;set;}
        public string skeduloAPIToken {get;set;}
        public string jobURL {get;set;}
        public boolean enableObjectSync {get;set;}
        
        public string nexmoApiKey {get;set;}
        public string nexmoApiSecret {get;set;}
        public string nexmoFromNumber {get;set;}
        public boolean sendEnrouteSms {get;set;}

        public skedAdminSetting() {
            sked_Admin_Setting__c setting = sked_Admin_Setting__c.getOrgDefaults();
        	this.velocity = 30;
            this.skeduloAPIToken = setting.sked_Skedulo_API_Token__c != NULL ? setting.sked_Skedulo_API_Token__c : '';
            this.jobURL = setting.sked_Global_JobURL__c != NULL ? setting.sked_Global_JobURL__c : '';
            this.enableObjectSync = setting.sked_Enable_Object_Sync__c;
            this.nexmoApiKey = setting.sked_Nexmo_Api_Key__c;
            this.nexmoApiSecret = setting.sked_Nexmo_Api_Secret__c;
            this.nexmoFromNumber = setting.sked_Nexmo_From_Number__c;
            this.sendEnrouteSms = setting.sked_Send_Enroute_SMS__c;
        }
    }

    public class skedRacSetting extends skedCalendarSettingBase {
        public boolean autoApproveAvailability {get;set;}
        public boolean enableActivity {get;set;}
        public boolean enableAvailabilityTemplate {get;set;}
        public boolean respectResourceTimezone {get;set;}

        public skedRacSetting() {
            sked_Admin_Setting__c setting = sked_Admin_Setting__c.getOrgDefaults();
            this.firstDay = setting.sked_RAC_First_Day__c != NULL ? integer.valueOf(setting.sked_RAC_First_Day__c) : 0;
            this.viewPeriod = setting.sked_RAC_View_Period__c != NULL ? integer.valueOf(setting.sked_RAC_View_Period__c) : 2;
            this.dateFormat = !string.isBlank(setting.sked_RAC_Date_Format__c) ? setting.sked_RAC_Date_Format__c : 'MM/dd/yyyy';
            this.datePickerFormat = !string.isBlank(setting.sked_RAC_Datepicker_Format__c) ? setting.sked_RAC_Datepicker_Format__c : 'D, mm/dd/yy';
            this.noOfRecurWeeks = setting.sked_RAC_No_of_Recur_Weeks__c != NULL ? integer.valueOf(setting.sked_RAC_No_of_Recur_Weeks__c) : 10;
            this.calendarStart = setting.sked_RAC_Calendar_Start__c != NULL ? integer.valueOf(setting.sked_RAC_Calendar_Start__c) : 700;
            this.calendarEnd = setting.sked_RAC_Calendar_End__c != NULL ? integer.valueOf(setting.sked_RAC_Calendar_End__c) : 1900;
            this.calendarStep = setting.sked_RAC_Calendar_Step__c != NULL ? integer.valueOf(setting.sked_RAC_Calendar_Step__c) : 30;
            this.autoApproveAvailability = setting.sked_RAC_Auto_Approve_Availability__c;
            this.enableActivity = setting.sked_RAC_Enable_Activity__c;
            this.enableAvailabilityTemplate = setting.sked_RAC_Enable_Availability_Template__c;
            this.respectResourceTimezone = setting.sked_RAC_Respect_Resource_Timezone__c;

            List<string> objectTypes = new List<string>();
            objectTypes.add('availability');
            objectTypes.add('activity');
            objectTypes.add('job');
            this.mapShiftTypeSetting = getMapShiftTypeSetting(objectTypes);
        }
    }

    public class skedPacSetting extends skedCalendarSettingBase {
        public transient Map<string, skedModels.shiftTypeSetting> colorMap {get;set;}

        public skedPacSetting() {
            sked_Admin_Setting__c setting = sked_Admin_Setting__c.getOrgDefaults();
            this.firstDay = setting.sked_RAC_First_Day__c != NULL ? integer.valueOf(setting.sked_RAC_First_Day__c) : 0;
            this.viewPeriod = setting.sked_RAC_View_Period__c != NULL ? integer.valueOf(setting.sked_RAC_View_Period__c) : 2;
            this.dateFormat = !string.isBlank(setting.sked_RAC_Date_Format__c) ? setting.sked_RAC_Date_Format__c : 'MM/dd/yyyy';
            this.datePickerFormat = !string.isBlank(setting.sked_RAC_Datepicker_Format__c) ? setting.sked_RAC_Datepicker_Format__c : 'D, mm/dd/yy';
            this.noOfRecurWeeks = setting.sked_RAC_No_of_Recur_Weeks__c != NULL ? integer.valueOf(setting.sked_RAC_No_of_Recur_Weeks__c) : 10;
            this.calendarStart = setting.sked_RAC_Calendar_Start__c != NULL ? integer.valueOf(setting.sked_RAC_Calendar_Start__c) : 700;
            this.calendarEnd = setting.sked_RAC_Calendar_End__c != NULL ? integer.valueOf(setting.sked_RAC_Calendar_End__c) : 1900;
            this.calendarStep = setting.sked_RAC_Calendar_Step__c != NULL ? integer.valueOf(setting.sked_RAC_Calendar_Step__c) : 30;

            List<string> objectTypes = new List<string>();
            objectTypes.add('clientAvailability');
            objectTypes.add('job');
            this.mapShiftTypeSetting = getMapShiftTypeSetting(objectTypes);
        }
    }

    public class skedRmcSetting extends skedCalendarSettingBase {
        public transient Map<string, skedModels.displaySetting> jobStatusColorMap {get;set;}
        public transient skedModels.displaySetting shiftColor {get;set;}

        public skedRmcSetting() {
            sked_Admin_Setting__c setting = sked_Admin_Setting__c.getOrgDefaults();
            this.firstDay = 0;
            this.dateFormat = 'MM/dd/yyyy';
            this.datePickerFormat = 'D, mm/dd/yy';
            this.calendarStart = 700;
            this.calendarEnd = 1900;
            this.calendarStep = 30;

            this.shiftColor = new skedModels.displaySetting();
            List<sked_Shift_Type_Setting__mdt> skedShiftTypeSettings = [SELECT Id, sked_Background_Color__c, sked_Color__c
                                                                        FROM sked_Shift_Type_Setting__mdt
                                                                        WHERE sked_Is_Active__c = TRUE
                                                                        AND sked_Category__c = 'shift'];
            if (!skedShiftTypeSettings.isEmpty()) {
                sked_Shift_Type_Setting__mdt shiftSetting = skedShiftTypeSettings.get(0);
                this.shiftColor = new skedModels.displaySetting();
                this.shiftColor.backgroundColor = shiftSetting.sked_Background_Color__c;
                this.shiftColor.color = shiftSetting.sked_Color__c;
            }

            this.jobStatusColorMap = getMapdisplaySetting('jobStatus');
        }
    }

    public class skedBookingGridSetting extends skedCalendarSettingBase {
        public skedBookingGridSetting() {
            sked_Admin_Setting__c setting = sked_Admin_Setting__c.getOrgDefaults();
            this.firstDay = setting.sked_RAC_First_Day__c != NULL ? integer.valueOf(setting.sked_RAC_First_Day__c) : 0;
            this.viewPeriod = setting.sked_RAC_View_Period__c != NULL ? integer.valueOf(setting.sked_RAC_View_Period__c) : 2;
            this.dateFormat = !string.isBlank(setting.sked_RAC_Date_Format__c) ? setting.sked_RAC_Date_Format__c : 'MM/dd/yyyy';
            this.datePickerFormat = !string.isBlank(setting.sked_RAC_Datepicker_Format__c) ? setting.sked_RAC_Datepicker_Format__c : 'D, mm/dd/yy';
            this.noOfRecurWeeks = setting.sked_RAC_No_of_Recur_Weeks__c != NULL ? integer.valueOf(setting.sked_RAC_No_of_Recur_Weeks__c) : 10;
            this.calendarStart = setting.sked_RAC_Calendar_Start__c != NULL ? integer.valueOf(setting.sked_RAC_Calendar_Start__c) : 700;
            this.calendarEnd = setting.sked_RAC_Calendar_End__c != NULL ? integer.valueOf(setting.sked_RAC_Calendar_End__c) : 1900;
            this.calendarStep = setting.sked_RAC_Calendar_Step__c != NULL ? integer.valueOf(setting.sked_RAC_Calendar_Step__c) : 30;
        }
    }

    public abstract class skedCalendarSettingBase {
        public integer firstDay {get;set;}
        public integer viewPeriod {get;set;}
        public string dateFormat {get;set;}
        public string datePickerFormat {get;set;}
        public integer noOfRecurWeeks {get;set;}
        public integer calendarStart {get;set;}
        public integer calendarEnd {get;set;}
        public integer calendarStep {get;set;}
        public transient Map<string, skedModels.shiftTypeSetting> mapShiftTypeSetting {get;set;}

        protected Map<string, skedModels.shiftTypeSetting> getMapShiftTypeSetting(List<string> objectTypes) {
            Map<string, skedModels.shiftTypeSetting> results = new Map<string, skedModels.shiftTypeSetting>();
            List<sked_Shift_Type_Setting__mdt> skedShiftTypeSettings = [SELECT Id, sked_Item__c, sked_Available_Start__c, sked_Available_End__c,
                                                                        sked_Background_Color__c, sked_Can_Be_Pre_dated__c, sked_Color__c,
                                                                        sked_Short_Name__c, sked_Step__c, sked_Is_Available__c, sked_Show_Legend__c,
                                                                        sked_Category__c
                                                                        FROM sked_Shift_Type_Setting__mdt
                                                                        WHERE sked_Is_Active__c = TRUE
                                                                        AND sked_Category__c IN :objectTypes];
            if (skedShiftTypeSettings != NULL && skedShiftTypeSettings.size() > 0) {
                for (sked_Shift_Type_Setting__mdt skedShiftTypeSetting : skedShiftTypeSettings) {
                    skedModels.shiftTypeSetting model = new skedModels.shiftTypeSetting();
                    model.id = skedShiftTypeSetting.Id;
                    model.shiftType = skedShiftTypeSetting.sked_Item__c;
                    model.availableStart = integer.valueOf(skedShiftTypeSetting.sked_Available_Start__c);
                    model.availableEnd = integer.valueOf(skedShiftTypeSetting.sked_Available_End__c);
                    model.backgroundColor = skedShiftTypeSetting.sked_Background_Color__c;
                    model.canBePreDated = skedShiftTypeSetting.sked_Can_Be_Pre_dated__c;
                    model.color = skedShiftTypeSetting.sked_Color__c;
                    model.shortName = skedShiftTypeSetting.sked_Short_Name__c;
                    model.isAvailable = skedShiftTypeSetting.sked_Is_Available__c;
                    model.objectType = skedShiftTypeSetting.sked_Category__c;
                    model.step = integer.valueOf(skedShiftTypeSetting.sked_Step__c);
                    model.showLegend = skedShiftTypeSetting.sked_Show_Legend__c;
                    results.put(model.shiftType, model);
                }
            }
            return results;
        }

        protected Map<string, skedModels.displaySetting> getMapdisplaySetting(string category) {
            Map<string, skedModels.displaySetting> results = new Map<string, skedModels.displaySetting>();
            List<sked_Shift_Type_Setting__mdt> skedShiftTypeSettings = [SELECT Id, sked_Item__c, sked_Background_Color__c,
                                                                        sked_Color__c, sked_Show_Legend__c
                                                                        FROM sked_Shift_Type_Setting__mdt
                                                                        WHERE sked_Is_Active__c = TRUE
                                                                        AND sked_Category__c = :category];
            if (skedShiftTypeSettings != NULL && skedShiftTypeSettings.size() > 0) {
                for (sked_Shift_Type_Setting__mdt skedShiftTypeSetting : skedShiftTypeSettings) {
                    skedModels.displaySetting model = new skedModels.displaySetting();
                    model.id = skedShiftTypeSetting.Id;
                    model.backgroundColor = skedShiftTypeSetting.sked_Background_Color__c;
                    model.color = skedShiftTypeSetting.sked_Color__c;
                    model.showLegend = skedShiftTypeSetting.sked_Show_Legend__c;
                    results.put(skedShiftTypeSetting.sked_Item__c, model);
                }
            }
            return results;
        }
    }
    
}