+++ 
date = 2019-06-29T23:56:05+05:30
title = "Where the data from your Windows 10 machine is going"
description = "Windows 10 includes a piece of software called the Connected User Experience and Telemetry component, also known as the Universal Telemetry Client (UTC). It runs as a Windows service with the display name DiagTrack and the actual service name utcsvc. Microsoft has engineered this component as a part of Windows. You can see the DiagTrack service in the Services console in Windows 10. It’s not a secret."
slug = ""
authors = []
tags = ["windows", "telemetry", "data", "privacy", "security"]
categories = []
externalLink = ""
series = []
+++

Windows 10 includes a piece of software called the Connected User Experience and Telemetry component, also known as the Universal Telemetry Client (UTC). It runs as a Windows service with the display name DiagTrack and the actual service name utcsvc. Microsoft has engineered this component as a part of Windows. You can see the `DiagTrack` service in the Services console in Windows 10. It's not a secret.

To find the process ID (PID) for the service, look on the Services tab in Windows Task Manager. This piece of information is useful for anyone who wants to monitor activities of the DiagTrack service using other software tools. I used that PID to watch the activity of the DiagTrack service.

## What data is collected from a Windows 10 machine?

Telemetry data includes information about the device and how it's configured (including hardware attributes such as CPU, installed memory, and storage), as well as quality-related information such as uptime and sleep details and the number of crashes or hangs. Additional basic information includes a list of installed apps and drivers. For systems where the telemetry is set to a level higher than Basic, the information collected includes events that analyze interaction between the user and the operating system and apps.

## Where is the telemetry data stored?

On a Windows 10 machine, telemetry data is stored in encrypted files in the hidden **%ProgramData%\Microsoft\Diagnosis** folder. The files and folders in this location are not accessible to normal users and have permissions that make it difficult to snoop in them. Even if you could look into the contents of those files, there's nothing to see, because the data files are encrypted locally.

## Where is all the data going?

Moment of truth. You can find the DNS hostnames below. Unfortunately hostnames like these aren't super helpful. Different people can look up the hostnames to different IP addresses, depending on their location. Routers need IP ranges to block, not hostnames.

```console
- vortex.data.microsoft.com
- vortex-win.data.microsoft.com
- telecommand.telemetry.microsoft.com
- telecommand.telemetry.microsoft.com.nsatc.net
- oca.telemetry.microsoft.com
- oca.telemetry.microsoft.com.nsatc.net
- sqm.telemetry.microsoft.com
- sqm.telemetry.microsoft.com.nsatc.net
- watson.telemetry.microsoft.com
- watson.telemetry.microsoft.com.nsatc.net
- redir.metaservices.microsoft.com
- choice.microsoft.com
- choice.microsoft.com.nsatc.net
- df.telemetry.microsoft.com
- reports.wes.df.telemetry.microsoft.com
- wes.df.telemetry.microsoft.com
- services.wes.df.telemetry.microsoft.com
- sqm.df.telemetry.microsoft.com
- telemetry.microsoft.com
- watson.ppe.telemetry.microsoft.com
- telemetry.appex.bing.net
- telemetry.urs.microsoft.com
- urs.microsoft.com
- bing.com
- telemetry.appex.bing.net:443
- settings-sandbox.data.microsoft.com
- vortex-sandbox.data.microsoft.com
- survey.watson.microsoft.com
- watson.live.com
- watson.microsoft.com
- statsfe2.ws.microsoft.com
- corpext.msitadfs.glbdns2.microsoft.com
- compatexchange.cloudapp.net
- cs1.wpc.v0cdn.net
- a-0001.a-msedge.net
- statsfe2.update.microsoft.com.akadns.net
- sls.update.microsoft.com.akadns.net
- fe2.update.microsoft.com.akadns.net
- diagnostics.support.microsoft.com
- corp.sts.microsoft.com
- statsfe1.ws.microsoft.com
- pre.footprintpredict.com
- i1.services.social.microsoft.com
- i1.services.social.microsoft.com.nsatc.net
- feedback.windows.com
- feedback.microsoft-hohm.com
- feedback.search.microsoft.com
- public-family.api.account.microsoft.com
- adnxs.com
- c.msn.com
- g.msn.com
- h1.msn.com
- msedge.net
- rad.msn.com
- ads.msn.com
- adnexus.net
- ac3.msn.com
- c.atdmt.com
- m.adnxs.com
- sO.2mdn.net
- ads1.msn.com
- ec.atdmt.com
- flex.msn.com
- rad.live.com
- ui.skype.com
- msftncsi.com
- a-msedge.net
- a.rad.msn.com
- b.rad.msn.com
- cdn.atdmt.com
- m.hotmail.com
- ads1.msads.net
- a.ads1.msn.com
- a.ads2.msn.com
- apps.skype.com
- b.ads1.msn.com
- view.atdmt.com
- preview.msn.com
- aidps.atdmt.com
- static.2mdn.net
- a.ads2.msads.net
- b.ads2.msads.net
- db3aqu.atdmt.com
- secure.adnxs.com
- www.msftncsi.com
- live.rads.msn.com
- ad.doubleclick.net
- bs.serving-sys.com
- pricelist.skype.com
- a-0002.a-msedge.net
- a-0003.a-msedge.net
- a-0004.a-msedge.net
- a-0005.a-msedge.net
- a-0006.a-msedge.net
- a-0007.a-msedge.net
- a-0008.a-msedge.net
- a-0009.a-msedge.net
- aka-cdn-ns.adtech.de
- cds26.ams9.msecn.net
- lb1.www.ms.akadns.net
- az361816.vo.msecnd.net
- az512334.vo.msecnd.net
- msntest.serving-sys.com
- secure.flashtalking.com
- s.gateway.messenger.live.com
- schemas.microsoft.akadns.net
- settings-win.data.microsoft.com
- msnbot-65-55-108-23.search.msn.com
- vortex-bn2.metron.live.com.nsatc.net
- vortex-cy2.metron.live.com.nsatc.net
- www.vortex.data.microsoft.com
- www.vortex-win.data.microsoft.com
- www.telecommand.telemetry.microsoft.com
- www.telecommand.telemetry.microsoft.com.nsatc.net
- www.oca.telemetry.microsoft.com
- www.oca.telemetry.microsoft.com.nsatc.net
- www.sqm.telemetry.microsoft.com
- www.sqm.telemetry.microsoft.com.nsatc.net
- www.watson.telemetry.microsoft.com
- www.watson.telemetry.microsoft.com.nsatc.net
- www.redir.metaservices.microsoft.com
- www.choice.microsoft.com
- www.choice.microsoft.com.nsatc.net
- www.df.telemetry.microsoft.com
- www.reports.wes.df.telemetry.microsoft.com
- www.wes.df.telemetry.microsoft.com
- www.services.wes.df.telemetry.microsoft.com
- www.sqm.df.telemetry.microsoft.com
- www.telemetry.microsoft.com
- www.watson.ppe.telemetry.microsoft.com
- www.telemetry.appex.bing.net
- www.telemetry.urs.microsoft.com
- www.urs.microsoft.com
- www.bing.com
- www.telemetry.appex.bing.net:443
- www.settings-sandbox.data.microsoft.com
- www.vortex-sandbox.data.microsoft.com
- www.survey.watson.microsoft.com
- www.watson.live.com
- www.watson.microsoft.com
- www.statsfe2.ws.microsoft.com
- www.corpext.msitadfs.glbdns2.microsoft.com
- www.compatexchange.cloudapp.net
- www.cs1.wpc.v0cdn.net
- www.a-0001.a-msedge.net
- www.statsfe2.update.microsoft.com.akadns.net
- www.sls.update.microsoft.com.akadns.net
- www.fe2.update.microsoft.com.akadns.net
- www.diagnostics.support.microsoft.com
- www.corp.sts.microsoft.com
- www.statsfe1.ws.microsoft.com
- www.pre.footprintpredict.com
- www.i1.services.social.microsoft.com
- www.i1.services.social.microsoft.com.nsatc.net
- www.feedback.windows.com
- www.feedback.microsoft-hohm.com
- www.feedback.search.microsoft.com
- www.public-family.api.account.microsoft.com
- www.adnxs.com
- www.c.msn.com
- www.g.msn.com
- www.h1.msn.com
- www.msedge.net
- www.rad.msn.com
- www.ads.msn.com
- www.adnexus.net
- www.ac3.msn.com
- www.c.atdmt.com
- www.m.adnxs.com
- www.sO.2mdn.net
- www.ads1.msn.com
- www.ec.atdmt.com
- www.flex.msn.com
- www.rad.live.com
- www.ui.skype.com
- www.msftncsi.com
- www.a-msedge.net
- www.a.rad.msn.com
- www.b.rad.msn.com
- www.cdn.atdmt.com
- www.m.hotmail.com
- www.ads1.msads.net
- www.a.ads1.msn.com
- www.a.ads2.msn.com
- www.apps.skype.com
- www.b.ads1.msn.com
- www.view.atdmt.com
- www.preview.msn.com
- www.aidps.atdmt.com
- www.static.2mdn.net
- www.a.ads2.msads.net
- www.b.ads2.msads.net
- www.db3aqu.atdmt.com
- www.secure.adnxs.com
- www.www.msftncsi.com
- www.live.rads.msn.com
- www.ad.doubleclick.net
- www.bs.serving-sys.com
- www.pricelist.skype.com
- www.a-0002.a-msedge.net
- www.a-0003.a-msedge.net
- www.a-0004.a-msedge.net
- www.a-0005.a-msedge.net
- www.a-0006.a-msedge.net
- www.a-0007.a-msedge.net
- www.a-0008.a-msedge.net
- www.a-0009.a-msedge.net
- www.aka-cdn-ns.adtech.de
- www.cds26.ams9.msecn.net
- www.lb1.www.ms.akadns.net
- www.az361816.vo.msecnd.net
- www.az512334.vo.msecnd.net
- www.msntest.serving-sys.com
- www.secure.flashtalking.com
- www.s.gateway.messenger.live.com
- www.schemas.microsoft.akadns.net
- www.settings-win.data.microsoft.com
- www.msnbot-65-55-108-23.search.msn.com
- www.vortex-bn2.metron.live.com.nsatc.net
- www.vortex-cy2.metron.live.com.nsatc.net
```

If you want to minimize telemetry, you can disable the `DiagTrack` service and put the above hostnames in your hosts file. That should block outgoing traffic. You can use Wireshark or any other packet monitoriong tool such as [this](https://github.com/abhishekwl/Network-monitor) to check it out yourself.

</div>
