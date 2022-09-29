# -TES3MP-Miscellaneous

A repository of tes3mp scripts that I did not have a category for

## Restock Merchants Gold

A script that allows to define a period after which the merchants' gold will get restocked.

The period can be defined either in:

<ol>
<li>in-game time - hours and days</li>
<li>real-time - seconds</li>
</ol>

### Configuration

*script.config.useRealTime* - either *true* or *false*, determines whether to use a real-time or in-game time

*script.config.restockGoldSeconds* - only available if using real-time; determines amount after which the gold gets restocked

*script.config.restockGoldDays* - only available if using in-game time; determines an amount of days after which the gold gets restocked

*script.config.restockGoldHours* - only available if using in-game time; determines an amount of hours after which the gold gets restocked

### Installation

<ol>
<li>For the initial gold pool to be set up correctly, please delete the contents of <tes3mp>/server/data/cells</li>
<li>Create a folder restockMerchantsGold in <tes3mp>/server/scripts/custom</li>
<li>Add main.lua in that created folder</li>
<li>Open customScripts.lua and put there this line: require("custom.restockMerchantsGold.main")</li>
<li>Save customScripts.lua and launch the server</li>
<li>To confirm the script is running fine, you should see "[RestockMerchantsGold] Running..." among the first few lines of server console</li>                                                                                                                                    

### Showcase
[![Restock Merchants Gold showcase](https://i.ytimg.com/vi/vAsz7pjNcBE/hqdefault.jpg)](https://www.youtube.com/watch?v=vAsz7pjNcBE)
