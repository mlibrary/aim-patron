This will continue to be its own application and not be folded into the `aim`
repository.

Files will get dumped into an `empty_dir` in kubernetes. Maybe `scratch`.

Use Yabeda for metrics. Since this is a job, the metrics will be pushed. Maybe
try the https://github.com/zapier/prom-aggregation-gateway

Output logs to stdout. Should do it with structured logs. 

Rename to be `aim-` `aim-mcommunity` or `aim-patron-load`. 

Compare output to real data. Experiment with subset of data. We need to be able
to compare xml generated from this with xml generated from the original. 

Write up the packaging and sending the xml output to alma-integrations. 

Set up kubernetes to actually do all of this stuff. 
  - Cronjob with container that runs this script. Probably takes in some
    arguments. date or duration? For most days.
  - Cronjob for full dumps. 

Hooking up MCommunity integration in Alma


Next step is figuring out the data comparison

