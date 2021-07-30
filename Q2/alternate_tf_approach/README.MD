This is an alternate approach using modules and json input files.

Benefits:

- It scales well, since the input and the resources have been split.
- the modules and the inputscan now be versioned independently
- Easier to maintain and manage. SREs can manage the modules while the inputs can be tweaked by sysadmins or devs for self service.
- state information can now be isolated per environment.