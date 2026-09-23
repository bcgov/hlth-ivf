String jobName = 'Daily_IVF_Treatment_Status_Update';

List<CronTrigger> existingJobs = [
    SELECT Id
    FROM CronTrigger
    WHERE CronJobDetail.Name = :jobName
];

for (CronTrigger job : existingJobs) {
    System.abortJob(job.Id);
}

System.schedule(
    jobName,
    '0 0 1 * * ?',
    new IVFTreatmentStatusBatch()
);