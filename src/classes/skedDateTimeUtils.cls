public class skedDateTimeUtils {

    public static final string DATE_FORMAT = 'MM/dd/yyyy';
    public static final string TIME_FORMAT = 'h:mm a';
    public static final string DATE_TIME_FORMAT = 'MM/dd/yyyy hh:mm a';
    public static final string DATE_ISO_FORMAT = 'yyyy-MM-dd';
    public static final string DATE_TIME_ISO_FORMAT = 'yyyy-MM-ddThh:mm:ssZ';
    public static final string SHORT_DATE_FORMAT = 'MM/dd';
    
    public static DateTime toTimezone(DateTime input, string toTimezoneSidId) {
        return switchTimezone(input, UserInfo.getTimeZone().getID(), toTimezoneSidId);
    }
    
    public static DateTime switchTimezone(DateTime input, string fromTimezoneSidId, string toTimezoneSidId) {
        if (fromTimezoneSidId == toTimezoneSidId) {
            return input;
        }
        TimeZone fromTz = Timezone.getTimeZone(fromTimezoneSidId);
        Timezone toTz = Timezone.getTimeZone(toTimezoneSidId);
        integer offsetMinutes = fromTz.getOffset(input) - toTz.getOffset(input);
        offsetMinutes = offsetMinutes / 60000;
        
        input = addMinutes(input, offsetMinutes, toTimezoneSidId);
        return input;
    }
    
    public static DateTime addMinutes(DateTime input, integer minutes, string timezoneSidId) {
        DateTime result = input.addMinutes(minutes);
        Timezone tz = Timezone.getTimezone(timezoneSidId);
        integer inputOffset = tz.getOffset(input) / 60000;
        integer resultOffset = tz.getOffset(result) / 60000;
        result = result.addMinutes(inputOffset - resultOffset);
        
        return result;
    }
    
    public static DateTime addDays(DateTime input, integer days, string timezoneSidId) {
        DateTime result = input.addDays(days);
        Timezone tz = Timezone.getTimezone(timezoneSidId);
        integer inputOffset = tz.getOffset(input) / 60000;
        integer resultOffset = tz.getOffset(result) / 60000;
        result = result.addMinutes(inputOffset - resultOffset);
        
        return result;
    } 
    
    public static DateTime addMonths(DateTime input, integer months, string timezoneSidId) {
        DateTime result = input.addMonths(months);
        Timezone tz = Timezone.getTimezone(timezoneSidId);
        integer inputOffset = tz.getOffset(input) / 60000;
        integer resultOffset = tz.getOffset(result) / 60000;
        result = result.addMinutes(inputOffset - resultOffset);
        
        return result;
    } 
    
    public static DateTime addYears(DateTime input, integer years, string timezoneSidId) {
        DateTime result = input.addYears(years);
        Timezone tz = Timezone.getTimezone(timezoneSidId);
        integer inputOffset = tz.getOffset(input) / 60000;
        integer resultOffset = tz.getOffset(result) / 60000;
        result = result.addMinutes(inputOffset - resultOffset);
        
        return result;
    } 
    
    public static Date getDate(DateTime input, string timezoneSidId) {
        string dateIsoString = input.format(DATE_ISO_FORMAT, timezoneSidId);
        return (Date)Json.deserialize('"' + dateIsoString + '"', Date.class);
    }
    
    public static Date getDateFromIsoString(string isoString) {
        return (Date)Json.deserialize('"' + isoString + '"', Date.class);
    }
    
    public static DateTime getDateTimeFromIsoString(string isoString) {
        return (DateTime)Json.deserialize('"' + isoString + '"', DateTime.class);
    }
    
    public static DateTime getStartOfDate(DateTime input, string timezoneSidId) {
        Date inputDate = getDate(input, timezoneSidId);
        return getStartOfDate(inputDate, timezoneSidId);
    }
    
    public static DateTime getStartOfDate(Date input, string timezoneSidId) {
        DateTime result = DateTime.newInstance(input, time.newInstance(0, 0, 0, 0));
        result = toTimezone(result, timezoneSidId);
        return result;
    }
    
    public static DateTime getEndOfDate(Date input, string timezoneSidId) {
        DateTime dateStart = getStartOfDate(input, timezoneSidId);
        return addDays(dateStart, 1, timezoneSidId);
    }
    
    public static DateTime getEndOfDate(DateTime input, string timezoneSidId) {
        DateTime dateStart = getStartOfDate(input, timezoneSidId);
        return addDays(dateStart, 1, timezoneSidId);
    }
    
    public static integer convertTimeNumberToMinutes(decimal input) {
        integer inputInt = integer.valueOf(input);
        return integer.valueOf(inputInt / 100) * 60 + Math.mod(inputInt, 100);
    }
    
    public static integer getDifferenteMinutes(DateTime dtime1, DateTime dTime2) {
        return Integer.valueOf((dTime2.getTime() - dtime1.getTime()) / 60000);
    }

}