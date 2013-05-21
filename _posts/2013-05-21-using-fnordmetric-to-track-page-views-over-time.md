---
layout: post
tags: []
title: Using Fnordmetric to track page views over time
---

[Fnordmetric](https://github.com/paulasmuth/fnordmetric) is an event-tracking app designed to help you keep track of application metrics by constructing and visualizing timeseries. It took me some time to understand how this all worked - what is a gauge, a timeserie, how do the backend and the frontend of Fnordmetric communicate with Redis. This article is not aimed at summing up all of these aspects, but simply at helping to understand some basics on how the Fnordmetric backend works.

Timeseries are a sequence of data points measured at regular time intervals. It is particularly useful to show the progress of data over time. The advantage of using timeseries to represent event-based metrics is simple: by storing and updating key/values pairs into data buckets - called *gauges* - every time an event occurs, data-points emerge over time, and can be visualised simply by sending basic read operations to the datastore. This means that data computation is separated over time, rather than being done at access time.

As an example, say we want to visualise page views per minute on a graph. One approach would be to store all `page_view` events in the datastore (whether it's Redis, PostgreSQL or anything else) along with the time when the event occurs, additional data like a URL etc… Then at the moment when we load the visualisation, read all the `page_view` events and group them by time period (minutes) with some fancy requests.
The thing is, if you have a lot of page views per minute, and if you want to refresh the graph, say every second,  that will be a lot of computation (reads and group bys) to do at access time!

I will now walk you through the way of implementing this with Fnordmetric so that you see how it takes a different approach. We will also look at what happens in Redis when Fnordmetric is running.

First off you have to add a gauge in the Fnordmetric app.

{% highlight ruby %}
gauge :page_views_per_minute, 
  :tick => 1.minute.to_i, 
  :title => "Page views per minute"
{% endhighlight %}

This will create a new bucket of type `page_views_per_minute` every minute in which numerical values representing page views can be stored and combined. In our case each active bucket will contain a count of page views that is incremented over the 1 minute activity period. Concretely each bucket of type `page_views_per_minue` will be associated a timestamp to identify them.

Then, we should define when and how do we fill this bucket:

{% highlight ruby %}
event :page_view do
  incr :page_views_per_minute
end
{% endhighlight %}

This means "When receiving a `page_view` event, take the value of the currently active bucket of type `page_view_per_minute` and increment it by one."

Whith the code above our timeserie is now stored. To visualise the data points (page views count for each minute) in a graph on the Fnordmetric frontend, we have to create a widget:

{% highlight ruby %}
widget "Page Views",
  title: "Views per Minute",
  type: :timeline,
  width: 100,
  gauges: :page_views_per_minute,
  include_current: true,
  autoupdate: 1
{% endhighlight %}

As you can see, there is a reference to the gauge we've created. `include_current` is to display the value of the current bucket/gauge before the end of its activity period. `autoupdate` is to refresh the graph automatically every second (websockets are used).

Now, let's see what actually happens in Redis when a page view occurs. The event I'm sending here could be sent this way:

{% highlight sh%}
curl -X POST 
     -d '{ "action": "PageView", "path": "/index.html", "_type": "page_view" }'
     localhost:2323
{% endhighlight %}

{% highlight sh%}
~ » redis-cli
redis 127.0.0.1:6379> monitor
1369161446.675177 [0 127.0.0.1:37246] "hincrby" "fnordmetric-stats" "events_received" "1"
1369161446.675840 [0 127.0.0.1:37246] "set" "fnordmetric-event-6lcy8kmwe1ypt6ev1jj" "{\"action\":\"PageView\",\"path\":\"/index.html\",\"_type\":\"page_view\"}"
1369161446.676367 [0 127.0.0.1:37246] "lpush" "fnordmetric-queue" "6lcy8kmwe1ypt6ev1jj"
1369161446.677744 [0 127.0.0.1:37269] "get" "fnordmetric-event-6lcy8kmwe1ypt6ev1jj"
1369161446.678041 [0 127.0.0.1:37269] "blpop" "fnordmetric-queue" "1"
1369161448.084216 [0 127.0.0.1:37269] "hincrby" "fnordmetric-stats" "events_processed" "1"
1369161448.084346 [0 127.0.0.1:37269] "hsetnx" "fnordmetric-loomio-gauge-page_views_per_minute-60" "1369161420" "0"
1369161448.084446 [0 127.0.0.1:37269] "publish" "fnordmetric-announce" "{\"action\":\"PageView\",\"path\":\"/index.html\",\"_type\":\"page_view\",\"_time\":1369161446,\"_eid\":\"6lcy8kmwe1ypt6ev1jj\"}"
1369161448.085887 [0 127.0.0.1:37269] "hincrby" "fnordmetric-loomio-gauge-page_views_per_minute-60" "1369161420" "1"
{% endhighlight %}

Paying attention to the different ports being used, you will notice that, chronologically:

1. An event has been received. Service A (port 37246), increments the appropriate counter
2. Service A stores the "page_view" event as a set
3. Service A pushes this event to a queue
4. Service B (port 37269) retrieves the event from the queue
5. Service B reads from the queue (while blocking access to it)
6. Service B increments a counter of the number of events processed
7. If the {gauge, timestamp} keypair is new, Service B sets its value to 0
8. Service B publishes (outputs) that an event has occured
9. Service B Increments the currently active `page_view_per_minute` gauge by one.

If you repeat a page load within less than 1 minute, you'll see the timestamp for the gauge incremented will be the same (so the same gauge is going to be incremented).

Finally, let's see what happens when we load the graph in the Fnordmetric UI at localhost:4242.

{% highlight sh%}
~ » redis-cli
redis 127.0.0.1:6379> monitor
1369... [0 127.0.0.1:37316] "hmget" "fnordmetric-loomio-gauge-page_views_per_minute-60-mean-counts" "1369161900" ... "1369163700"
1369... [0 127.0.0.1:37316] "hmget" "fnordmetric-loomio-gauge-page_views_per_minute-60" "1369161900" ... "1369163700"
1369... [0 127.0.0.1:37316] "hmget" "fnordmetric-loomio-gauge-page_views_per_minute-60-mean-counts" "1369161900" ... "1369163700"
....
{% endhighlight %}


What is important to see here, is that we're only doing simple `hmget` calls, that read the content of our gauge. The result of the queries are directly used to populate the graph. In our case, new queries are sent every second (we specified a refresh time of 1 second when creating the widget).

Don't hesitate to correct possible mistakes or to send reactions in comments.

