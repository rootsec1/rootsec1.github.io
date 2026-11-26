+++
title = "Engineering experience"
description = "Abhishek Murthy is a founding engineer at ProSights in New York. His work spans AI agents, financial document extraction, and supply chain systems at Blinkit."
date = "2022-06-14"
lastmod = "2026-11-26"
aliases = ["about", "abhishek", "contact"]
author = "Abhishek Murthy"
+++

I’m Abhishek Murthy, a founding engineer at ProSights (YC W24) in New York. I build software that helps financial analysts get data out of documents and use it in Excel.

[Read my résumé (PDF)](/docs/AbhishekMurthy_Resume.pdf) · [Latest résumé on Google Docs]({{< social-url "Resume" >}}) · [LinkedIn]({{< social-url "LinkedIn" >}}) · [GitHub]({{< social-url "Github" >}})

## What I’ve built

**ProSights.** I built Architect, a Python and PostgreSQL workflow engine that runs agents on Kubernetes. With Restate tracking each step, an analyst can rerun a failed step without repeating the entire workflow. I also led engineering for Recreate, which converts financial reports and presentations into Excel or JSON. It processes about 3,000 pages per minute with over 94% table-extraction accuracy. Routing pages to different models based on what they contained cut inference costs by 27%.

**Ticketdude.** I co-founded an event ticketing company and built the Flutter app, React web app, and Django backend. I owned the path from payment to QR check-in. Tuning Django and MySQL cut the check-in API’s 90th-percentile latency by 29%.

**Blinkit.** I built inventory replenishment software for a grocery delivery network handling over 500,000 orders a day. Later, I led the fintech engineering team. We cut financial report generation time by 25% by changing how we read DynamoDB and aggregated data in Redshift. [My first year at Blinkit, in the company’s engineering blog](https://blinkit.com/blog/first-12-months-blinkit-abhishek-m).

**Tvast.** I built web and mobile tools for fuel-station operators at Shell. Managers used them to schedule staff and reconcile cash across shifts.

I earned my Master of Engineering in Artificial Intelligence at Duke University, where I helped students deploy applications on AWS, Azure, and Google Cloud.

## Engineering notes

- [Durable OCR pipelines]({{< relref "posts/building-pdf-extraction-pipelines-that-survive-real-documents" >}}) covers how to retry one failed page of a PDF and keep the source coordinates for an extracted value.
- [Building a search engine that fits in your L3 cache]({{< relref "posts/search-engine-fits-in-l3-cache" >}}) follows a ranked query through the index and explains where memory access costs more than scoring.
- [The harness is the product]({{< relref "posts/the-harness-is-the-product" >}}) explains how I think about tool permissions, execution traces, and verifying an AI agent’s work.

## Outside work

I’m interested in self-driving cars, robotics, and building AGI. One of my weekend projects was [teaching a bot to drive in Need for Speed Rivals]({{< relref "posts/nfs-self-driving-car-bot" >}}).

![My desk setup](./setup.jpg)

I am a huge fan of [@elonmusk](https://twitter.com/elonmusk), [@sama](https://twitter.com/sama) and [@realgeorgehotz](https://twitter.com/realgeorgehotz). The [geohot archive](https://www.youtube.com/@geohotarchive) is a treasure trove. During undergrad I won numerous national and international hackathons multiple times such as the [Singapore India Hackathon](https://singaporeindiahackathon.com/) and [Smart India Hackathon](https://www.sih.gov.in/) with over **100K+** participants. I was also a [Google Developer Club Lead](https://developers.google.com/community/gdsc) as a part of which I led the Bangalore community and held several Android app development workshops across the country. I occasionally perform pen tests and vulnerability assessments on backend servers and mobile apps (frida ftw).

I love anime, dark humor, elon's memes and [r/ExperiencedDevs](https://www.reddit.com/r/ExperiencedDevs/). I am one of the proud owners of an Xbox series X. My favorite games are Cyberpunk 2077 (doesn't deserve all that hate) and RDR2.

We're another day closer to building God, have a great day.
