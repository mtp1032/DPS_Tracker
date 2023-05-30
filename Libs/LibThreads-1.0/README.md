# LibThreads-1.0 (Code name Talon)
An Asynchronous Non-preemptive Multithread Library for World of Warcraft Addon Developers

CURRENT VERSION: 1.0 
GitHub: https://github.com/mtp1032/LibThreads-1.0

DESCRIPTION:
LibThreads (code name Talon) is an API used to incorporate asynchronous, non-preemptive 
multithreading into WoW Addons. Talon provides the major features you would expect such 
as thread creation, signaling, delay, yield, and so forth. Here is a summary of some of 
the services that are available in this release.

Threads - creation, yield, join, exit, signal (set/get), state (active, suspended, terminated)
Signals - SIG_ALERT, SIG_TERMINATE, SIG_NONE_PENDING, and SIG_METRICS.
Tuning  - Get/Set clock interval, thread congestion metrics

Talon is designed to increase an addon's ability to take advantage of the WoW client's 
inherent asynchronicity by offering threads to which tasks can be assigned and then run 
asnchronously relative to the WoW client's execution code path. For example, the OnEvent() 
service is nothing more that a normal procedure call (i.e., the WoW client calls 'into' 
the addon's code). As such, OnEvent() does not return to its caller (the WoW client) 
until the addon is done with the event. By passing the event off to a Talon thread for 
asynchronous processing, the OnEvent() service can return immediately allowing the addon's 
thread to handle the event. This substantially increases the asynchronicity of an addon.

For more information and examples, see the WoWThreads Programmer's Guide in the Doc directory.
