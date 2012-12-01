---
layout: post
tags: []
title: Blogging simply with Jekyll
---

It's not the first time I'm starting a blog. I went from Blogger to Wordpress down to coding my own application. 

The first two got me spending more time trying to accommodate to their unappealing and overly complex interfaces than actually writing content. The DIY approach seemed to better suit my needs until I got bored with the technologies I had chosen at that time (PHP and Symfony 2) and realised there were no easy way to migrate all the work I had been doing to a different system.

When I got interested in ruby I started considering Content Management Systems like [Radiant](http://radiantcms.org) and [Refinery](http://refinerycms.com/), that seemed to be less time-consuming for blogging than writing my own [Ruby on Rails](http://rubyonrails.org) application. But it still seemed a bit of an overkill to me. I was finding the concept of having to log into a website to write my posts inappropriate and not on par with what tools like Git enable to do. 

So instead of searching yet another tool, I pondered how I could change my workflow to better fit my needs. I already had a text editor that I was quite familiar with (Vim), a tool to make sure what I write doesn't get lost and can be reverted to previous versions (Git), so basically I just missed *some kind of magic* that would generate a blog for me and embed all my posts files into it.

Jekyll allows me to do precisely that. It's a lightweight static site generator written in ruby. No database is used - blog posts are just plain text files which makes them suitable for revision control and off-line use.

Basically, when I want to create a new post I do:

{% highlight sh %}
rake new
{% endhighlight %}

then I am prompted for the title I want to give to my post, and a basic template of a blog post is opened in my editor of choice for me to build upon it. Text formatting is Markdown by default (can be configured to something else)

When I'm happy with what I get I just do:

{% highlight sh %}
rake deploy
{% endhighlight %}

and then Jekyll generates a website for me with all the posts I want to be published, which is then automatically deployed to my production server (using `rsync`).

That's basically it. No fuss.

When you first create your blog you just have to write a few templates and stylesheets so that Jekyll knows what the website it will generate should look like, and you're ready to go. You can also customise the configuration file and chose from a heap of one-file plugins (or write your own) to suit your needs.

Apart from being quite minimalistic (thus responsive, easy to get started with etc...), one of the best advantage of this tool is that it allows to migrate all blog posts to a different system without being dependent on a specific database, nor a specific technology. I'm considering to move to [Nanoc](http://nanoc.stoneship.org/) at some point, and I'm also looking at `Python` alternatives. Since it only took me a couple of hours to setup this website, starting over wouldn't feel like too much energy had been wasted.

You can read more about Jekyll [here](https://github.com/mojombo/jekyll), and feel free to browse [the source] of my blog (https://github.com/fuzzytern/cybercrumbs.net). If you want to have a better understanding of my workflow, the [Rakefile](https://github.com/fuzzytern/cybercrumbs.net/blob/master/Rakefile) can be a good place to start.
