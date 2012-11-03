require "rubygems"
require "bundler/setup"
require "shellwords"
require "yaml"


Bundler.require


def post_title? message
  print message
  STDIN.gets.chomp
end


def sluggize str
  str.downcase.gsub(/[^a-z0-9]+/, '-');
end


desc "Generate blog files"
task :generate do
  Jekyll::Site.new(Jekyll.configuration({
    "source" => ".",
    "destination" => "_site"
  })).process
end


desc "Create a new post"
task :new do
  title = post_title?('Title: ')
  filename = "_posts/#{Time.now.strftime('%Y-%m-%d')}-#{sluggize title}.md"

  if File.exist? filename
    puts "Can't create new post: \e[33m#{filename}\e[0m"
    puts " \e[31m- Path already exists.\e[0m"
    exit 1
  end

  File.open(filename, "w") do |post|
    post.puts "---"
    post.puts "layout: post"
    post.puts "tags: []"
    post.puts "title: #{title}"
    post.puts "---"
    post.puts ""
    post.puts "Once upon a time..."
  end

  puts "A new post was created for at:"
  puts " \e[32m#{filename}\e[0m"
end
