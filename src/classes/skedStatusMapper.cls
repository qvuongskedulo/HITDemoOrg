public class skedStatusMapper {
	public skedStatusMapper() {	
        this.initMapJobStatusToAllocation();
        this.initMapAllocationStatusToTask();
	}

    public Map<String, String> mapStatusJobToAllocation = new Map<String, String>();
    public Map<String, String> mapStatusAllocationToTask = new Map<String, String>();

    public Map<String, String> initMapJobStatusToAllocation() {
        mapStatusJobToAllocation.put(skedConstants.JOB_STATUS_QUEUED, '');
        mapStatusJobToAllocation.put(skedConstants.JOB_STATUS_PENDING_ALLOCATION, '');
        mapStatusJobToAllocation.put(skedConstants.JOB_STATUS_PENDING_DISPATCH, skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH);
        mapStatusJobToAllocation.put(skedConstants.JOB_STATUS_DISPATCHED, skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED);
        mapStatusJobToAllocation.put(skedConstants.JOB_STATUS_READY, skedConstants.JOB_ALLOCATION_STATUS_CONFIRMED);
        mapStatusJobToAllocation.put(skedConstants.JOB_STATUS_IN_PROGRESS, skedConstants.JOB_ALLOCATION_STATUS_IN_PROGRESS);
        mapStatusJobToAllocation.put(skedConstants.JOB_STATUS_COMPLETE, skedConstants.JOB_ALLOCATION_STATUS_COMPLETE);
        mapStatusJobToAllocation.put(skedConstants.JOB_STATUS_CANCELLED, skedConstants.JOB_ALLOCATION_STATUS_DELETED);

        return mapStatusJobToAllocation;
    }

    public Map<String, String> initMapAllocationStatusToTask() {
        mapStatusAllocationToTask.put(skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH, skedConstants.CARE_PLAN_TASK_STATUS_WAITING_FOR_SOMEONE_ELSE);
        mapStatusAllocationToTask.put(skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED, skedConstants.CARE_PLAN_TASK_STATUS_NOT_STARTED);
        mapStatusAllocationToTask.put(skedConstants.JOB_ALLOCATION_STATUS_CONFIRMED, skedConstants.CARE_PLAN_TASK_STATUS_NOT_STARTED);
        mapStatusAllocationToTask.put(skedConstants.JOB_ALLOCATION_STATUS_EN_ROUTE, skedConstants.CARE_PLAN_TASK_STATUS_IN_PROGRESS);
        mapStatusAllocationToTask.put(skedConstants.JOB_ALLOCATION_STATUS_CHECKED_IN, skedConstants.CARE_PLAN_TASK_STATUS_IN_PROGRESS);
        mapStatusAllocationToTask.put(skedConstants.JOB_ALLOCATION_STATUS_IN_PROGRESS, skedConstants.CARE_PLAN_TASK_STATUS_IN_PROGRESS);
        mapStatusAllocationToTask.put(skedConstants.JOB_ALLOCATION_STATUS_COMPLETE, skedConstants.CARE_PLAN_TASK_STATUS_COMPLETED);
        mapStatusAllocationToTask.put(skedConstants.JOB_ALLOCATION_STATUS_DECLINED, skedConstants.CARE_PLAN_TASK_STATUS_DEFERRED);
        mapStatusAllocationToTask.put(skedConstants.JOB_ALLOCATION_STATUS_DELETED, skedConstants.CARE_PLAN_TASK_STATUS_DEFERRED);

        return mapStatusAllocationToTask;
    }

    public string getTaskStatus(string jobAllocationStatus) {
        string taskStatus = '';
        try {
            if (this.mapStatusAllocationToTask == null || this.mapStatusAllocationToTask.size() == 0) {
                this.initMapAllocationStatusToTask();
            }

            taskStatus = this.mapStatusAllocationToTask.get(jobAllocationStatus);
        }
        catch (Exception ex) {
            taskStatus = skedConstants.CARE_PLAN_TASK_STATUS_NOT_STARTED;
        }

        return taskStatus;
    }

    public string getJobAllocationStatus(string jobStatus) {
        if (this.mapStatusJobToAllocation == null || this.mapStatusJobToAllocation.size() == 0) {
            this.initMapJobStatusToAllocation();
        }

        string allocationStatus = this.mapStatusJobToAllocation.get(jobStatus);
        return allocationStatus;
    }
}