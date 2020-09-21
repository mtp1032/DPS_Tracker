DPS_Tracker Version 1.0

CHANGES:
- Reissue of the original DPS_Tracker Addon

DESCRIPTION:
A small, efficient personal DPS tracker. For each encounter between a player and one or more Mobs. DPS_Tracker produces a 
detailed combat log and a combat summary. The summary is produced when the player leaves combat. The combat log 
produced by DPS_Tracker is similar to the Blizzard combat log. In addition, you can cut and paste the output into a
comma-delimited file for import into, say, Excel.

You can display the Tracker window while you fight, though I have found it distracting. Rather, when the fight is over click 
the red [X] minimap button and the Tracker window will pop up with the log and its summary (alternatively, type "/dps show"). 
When the player is finished examining the results simply click the red [X] button in the upper right corner to hide the window 
but retain the data. To delete the log entries, click the [Reset] button. Clicking the [Select] button permits the player to 
cut and paste the log into a text file.

NOTE: DPS_Tracker does not track the damage of a player's party or raid members. There are other excellent addons you should 
use for this function (e.g., Details, Recount, Skada)

FEATURES:

DPS_Tracker reports the combat log AND a summary of the encounter. Here's an example summary:

*** COMBAT SUMMARY ***
Combat Ended After 64.40 seconds
3584 total damage (55.65 DPS).
2719 periodic damage (75.86% of total)
Damage Resisted or Blocked by Target: 260 (7.25% of total damage)
26 damage absorbed by Isaiah (0.73%)
No failed casts (missed, dodged, or parried
-- Damage by School
Shadow: 3584 damage (100.00% of total)
-- Healing Stats
Total Healing: 1019
Total Critical Healing: 119 (11.68% of total)
Total Overhealing: 176 (17.27% of total)


TODO:
- Set the combat tracker to scroll the text upwards. At the moment, the combat records are posted to the end of the log and move downwards. At the end of combat, the player must manually scroll down to see the latest log entries and the combat summary.

USAGE:

Command Line Options
    /dps <parameter> where parameter is one of...
        help - prints this help message
        show - display the tracker window
		hide - hide the tracker window
        config - display DPS_Tracker's options menu using Blizzard's in-game option menu


