public class skedConstants {
    public static final string ACCCOUNT_SCORE_BLACKLIST = 'Do not schedule';
    public static final string ACCCOUNT_SCORE_WHITELIST = 'Preferred';
    
    public static final string AVAILABILITY_STATUS_APPROVED = 'Approved';
    public static final string AVAILABILITY_STATUS_PENDING = 'Pending';
    public static final string AVAILABILITY_STATUS_DECLINED = 'Declined';

    public static final string CARE_PLAN_TASK_STATUS_WAITING_FOR_SOMEONE_ELSE = 'Waiting for Someone Else';
    public static final string CARE_PLAN_TASK_STATUS_NOT_STARTED = 'Not Started';
    public static final string CARE_PLAN_TASK_STATUS_IN_PROGRESS = 'In Progress';
    public static final string CARE_PLAN_TASK_STATUS_COMPLETED = 'Completed';
    public static final string CARE_PLAN_TASK_STATUS_DEFERRED = 'Deferred';

    public static final string CASE_STATUS_CLOSED = 'Closed';

    public static final string EXCEPTION_CODE_TIME_CONFLICT = 'Time conflict';
    public static final string EXCEPTION_CODE_NO_ALLOCATION = 'No Allocation';
    public static final string EXCEPTION_CODE_MISSING_LOCATION = 'Missing Location';
    public static final string EXCEPTION_LOG_STATUS_CLOSED = 'Closed';
    public static final string EXCEPTION_LOG_STATUS_OPEN = 'Open';

    public static final string JOB_CANCELLATION_REASON_RESCHEDULED = 'Rescheduled';
    
    public static final string JOB_STATUS_CANCELLED = 'Cancelled';
    public static final string JOB_STATUS_COMPLETE = 'Complete';
    public static final string JOB_STATUS_DISPATCHED = 'Dispatched';
    public static final string JOB_STATUS_IN_PROGRESS = 'In Progress';
    public static final string JOB_STATUS_PENDING_ALLOCATION = 'Pending Allocation';
    public static final string JOB_STATUS_PENDING_DISPATCH = 'Pending Dispatch';
    public static final string JOB_STATUS_QUEUED = 'Queued';
    public static final string JOB_STATUS_READY = 'Ready';
    
    public static final string JOB_ALLOCATION_STATUS_COMPLETE = 'Complete';
    public static final string JOB_ALLOCATION_STATUS_CONFIRMED = 'Confirmed';
    public static final string JOB_ALLOCATION_STATUS_EN_ROUTE = 'En Route';
    public static final string JOB_ALLOCATION_STATUS_CHECKED_IN = 'Checked In';
    public static final string JOB_ALLOCATION_STATUS_DECLINED = 'Declined';
    public static final string JOB_ALLOCATION_STATUS_DELETED = 'Deleted';
    public static final string JOB_ALLOCATION_STATUS_DISPATCHED = 'Dispatched';
    public static final string JOB_ALLOCATION_STATUS_PENDING_DISPATCH = 'Pending Dispatch';
    public static final string JOB_ALLOCATION_STATUS_IN_PROGRESS = 'In Progress';

    public static final string JOB_OFFER_STATUS_OFFERED = 'Offered';
    public static final string JOB_OFFER_STATUS_ACCEPTED = 'Accepted';
    public static final string JOB_OFFER_STATUS_DECLINED = 'Declined';
    public static final string JOB_OFFER_STATUS_CANCELLED = 'Cancelled';

    public static final string JOB_TYPE_INITIAL_EVALUATION = 'Initial Evaluation';
    public static final string JOB_TYPE_TREATMENT = 'Treatment';
    public static final string JOB_TYPE_GROUP_EVENT = 'Group Event';

    public static final string RESOURCE_TYPE_PERSON = 'Person';
    public static final string RESOURCE_TYPE_ASSET = 'Asset';

    public static final string PERIOD_WEEK         = 'week';
    public static final string PERIOD_2WEEKS       = '2 weeks';
    public static final string PERIOD_MONTH        = 'month';
    public static final string PERIOD_FORTNIGHT    = 'Current Fortnightly Roster';

    public static final string OPPORTUNITY_STAGE_SCHEDULED_EVALUATION = 'Scheduled Evaluation';
    
    public static final string HOLIDAY_GLOBAL = 'global';
    
    public static final string EXCEPTION_CONCURRENCY = 'CONCURRENCY_ERROR';
    public static final string EXCEPTION_CONCURRENCY_PATIENT = 'CONCURRENCY_PATIENT_ERROR';
    public static final string JOB_HAS_NO_RESOURCE_ERROR = 'Cannot complete a job that is not assigned to any resource';
    
    public static final string CARE_PLAN_RECORD_TYPE = 'Care Plan Task';
}