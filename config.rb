# Activate and configure extensions
# https://middlemanapp.com/advanced/configuration/#configuring-extensions

print_paths = false  # set to true to output all paths
show_no_progress = false # set to true to show photos with no progress items (for debugging)

activate :autoprefixer do |prefix|
  prefix.browsers = "last 2 versions"
end

# Layouts
# https://middlemanapp.com/basics/layouts/

# Per-page layout changes
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

# With alternative layout
# page '/path/to/file.html', layout: 'other_layout'

# Proxy pages
# https://middlemanapp.com/advanced/dynamic-pages/

## To convert csv to yaml
## From: https://www.commandercoriander.net/blog/2013/06/22/a-quick-path-from-csv-to-yaml/
require 'csv'
require 'find'
# require 'yaml'

# My own versionof titlecase
# Aside from not needing a plugin or ActiveSupport, this skips converting '-' to spaces
def mytitlecase(phrase)
  titlized = phrase.gsub(/([a-z\d])([A-Z])/,'\1_\2') # convert "TheManWithoutAPast" to "The_Man_Without_A_Past"
  titlized.gsub!("_", " ") # convert "the_raiders_of_the_lost_ark" to "the raiders of the lost ark"
  # convert "the raiders of the lost ark" to "The Raiders of the Lost Ark"
  skip = ["a", "of", "the", "an", "and", "but", "or", "nor", "for"] # not an exhaustive list
  titlized = titlized.split(" ").each {|w| skip.include?(w) ? w : w.capitalize! }.join(" ")
  titlized[0] = titlized[0].capitalize # always capitalize first word (but do not re-lowercase the rest)
  titlized
end

helpers do
  def titlecase(phrase)
    titlized = phrase.gsub(/([a-z\d])([A-Z])/,'\1_\2') # convert "TheManWithoutAPast" to "The_Man_Without_A_Past"
    titlized.gsub!("_", " ") # convert "the_raiders_of_the_lost_ark" to "the raiders of the lost ark"
    # convert "the raiders of the lost ark" to "The Raiders of the Lost Ark"
    skip = ["a", "of", "the", "an", "and", "but", "or", "nor", "for"] # not an exhaustive list
    titlized = titlized.split(" ").each {|w| skip.include?(w) ? w : w.capitalize! }.join(" ")
    titlized[0] = titlized[0].capitalize # always capitalize first word (but do not re-lowercase the rest)
    titlized
  end
end

      
def original_path(item)
  image_name = item[:image].to_s
  if (item[:parent].to_s.empty?)
    path = "originals/#{item[:category]}/#{item[:album_escaped]}/#{image_name}".downcase
  else
    path = "originals/#{item[:category]}/#{item[:album_escaped]}/#{item[:parent]}/#{image_name}".downcase
  end
  path
end

def web_path(item)
  # This needs to stay in sync with the web site helper img_path()
  image_name = item[:image].to_s
  image_name = "unknown" if image_name.empty?
  extension = (image_name =~ /.*\.png$/) ? "png" : "jpg" # Keep pngs for transparency, otherwise, convert to jpg
  if (item[:parent].to_s.empty?)
    path = "source/images/#{item[:category]}/#{item[:album_escaped]}/#{item[:basename]}_1080.#{extension}".downcase
  else
    path = "source/images/#{item[:category]}/#{item[:album_escaped]}/#{item[:parent]}/#{item[:basename]}_1080.#{extension}".downcase
  end
  path
end

def save_to_images(item)
  unless item[:image]
    puts "Unable to convert #{item[:title]}"
    return
  end
  src_path = original_path(item)
  dest_path = web_path(item)
  unless File.exist?(dest_path) || src_path.include?("not_for_publication")
    parent_dir = File.split(File.expand_path(dest_path))[0]
    FileUtils.mkpath(parent_dir) # sips cannot make directories, so make sure they exist
    puts "Converting #{src_path}"
    puts " to #{dest_path}"
    # sips has a bug setting dpiHeight on JPEGs, so save reduced size first, then convert to JPEG
    # (Old) cmd = "sips -s format jpeg -Z 1080 #{src_path} --out #{dest_path}"
    # puts "sips -s dpiHeight 72 -s dpiWidth 72 -Z 1080 \"#{src_path}\" --out \"#{dest_path}\""
    `sips -s dpiHeight 72 -s dpiWidth 72 -Z 1080 "#{src_path}" --out "#{dest_path}"> /dev/null 2>&1`
    # also, skip converting png files (with transparency) to jpeg files
    `sips -s format jpeg "#{dest_path}" >> /dev/null 2>&1` unless dest_path =~ /.*\.png$/ # convert to JPEG
  end
  dest_path
end

def img_is_wide?(path)
  # returns true if image is wide (1080) (vs tall)
  s = `sips -g pixelWidth #{path}` # returns  "<image path>\n  pixelHeight: 1080\n"
  pixel_width = s.split.last
  pixel_width == "1080"
end

def read_csv(csv_file_path)
  # converts csv to array of hashes for each key in the. header
  data = CSV.read(csv_file_path, :headers => true).map(&:to_hash)

  data.each do |item|
    # symbolize_keys
    item.keys.each do |key|
      item[(key.to_s.downcase.to_sym rescue key) || key] = item.delete(key)
    end
    unless item[:album_escaped]
      unless item[:album]
        puts "No :album for #{item}"
      else
        item[:album_escaped] = item[:album].gsub(" ", "_").downcase
      end
    end
  end 

  # Remove any not_for_publication items
  data.delete_if {|item| item[:category] == "not_for_publication" || item[:album] == "not_for_publication"}

  # File.open('data.yml', 'w') { |f| f.write(data.to_yaml) }
  data
end

def write_csv(csv_file_path, array_of_hashes)
  CSV.open(csv_file_path, "wb") do |csv|
    keys = array_of_hashes.first.keys
    csv << keys # adds the attributes name on the first line
    array_of_hashes.each do |hash| 
      csv << keys.collect {|key| hash[key]}
    end
  end
end

def scan_originals(prev_items, new_items)
  # Aside from finding and adding any missed artwork, it will also sanitize the names of the images to replace spaces with _ and lowercase

  show_not_publication = false # set to true to see items in "show_not_publication" folders
  skip_progress = true # set to false to include progress items in new.csv

  original_path = "originals"
  all_items = []
  Find.find(original_path) {|path|
    all_items << path if path =~ /.*\.jpg$/i
    all_items << path if path =~ /.*\.jpeg$/i
    all_items << path if path =~ /.*\.tif$/i
    all_items << path if path =~ /.*\.png$/i
  }
  # now go through all items and get category, album, parent (if applicable) and name, add to prev_items if not found
  all_parents = []
  all_items.each {|p| 
    parts = p.split("/")[1..-1] # skip "original/" part of path e.g. oil > landscapes > title | parent
    category = parts[0]
    next if category == "support" # skip 'support' folder - not a real category
    album = parts[1]
    parent = ""
    image = nil

    if (parts.length > 4)
       puts "Skipping #{p} found in #{parts[2]} (folders under progress folders are not included)" 
    elsif album == "not_for_publication"
      puts "Skipping #{p} - not for publication" if show_not_publication
    elsif (parts.length > 3)
      parent = parts[2]
      all_parents << parent
      image = parts[3]
    else
      image = parts[2]
    end
    next unless image
    album_escaped = album.gsub(" ", "_").downcase
    album = mytitlecase(album)
    
    basename = File.basename(image, File.extname(image)) # remove extension
    title = mytitlecase(basename)
    basename = basename.gsub(" ", "_").downcase
    prev_item = prev_items.detect {|h| h[:image] == image}
    unless prev_item
      prev_item = {category:category, album:album, album_escaped:album_escaped, title: title, parent: parent, image:image}
      prev_items << prev_item
      unless skip_progress && !parent.empty?
        puts "Did not find #{title} for #{image} in CSV catalog, adding new item"
        new_items << prev_item
      end
    end
    prev_item[:basename] = basename
    
    save_to_images(prev_item) # this uses the escaped version and also downgrades them to a max of 1080x1080
  }
  
  # set :has_children to "true" if there is an entry with the basename as a parent
  prev_items.each {|item|
    basename = item[:basename]
    item[:has_children] = "true" if all_parents.any? {|sub_item| sub_item == basename}
  }
  prev_items
end

all_items = read_csv('Portfolio_Catalog.csv')
new_items = []
all_items = scan_originals(all_items, new_items) # copies and converts all images found in 'originals' folder to 'images'folder
FileUtils.cp_r 'originals/support/', 'source/images/' # also copy unmodified version of support images. in /originals folder

write_csv("new.csv", new_items) unless new_items.empty?
data_by_categories = all_items.group_by {|item| 
  if (!item[:category])
    if (item[:title])
      puts "#{item.title} is missing category"
    else
      puts "#{item.inspect} is badly formatted"
    end
  end
  item[:category].downcase.to_sym
}

set :all_images, data_by_categories # Used in email.html.erb

data_by_categories.each do |category, list|
  puts "#{category.to_s}/index.html".downcase if print_paths
  proxy(
    "#{category.to_s}/index.html".downcase,
    '/category.html',
    locals: {
      category: category,
      contents: list
    },
    :ignore => true
  )
  albums = list.group_by {|item| item[:album].downcase.to_sym}
  albums.each do |album, album_list|
    album_escaped = album_list[0][:album_escaped]
    puts "#{category.to_s}/#{album_escaped}/index.html".downcase if print_paths
    proxy(
      "#{category.to_s}/#{album_escaped}/index.html".downcase,
      '/album.html',
      locals: {
        category: category,
        album: album,
        album_escaped: album_escaped,
        contents: album_list,
      },
      :ignore => true
    )
    # create a proxy for each image in the list
    # First, create a hash of progress_items, where the key is the parent's base image name.
    # As images and parents can come in any order,  process all images before making any proxy's
    progress_items = {}
    standard_items = []
    album_list.each do |item|
      image_name = item[:image].to_s
      next if image_name.empty?
      basename = item[:basename]
      parent_tag = item[:parent].to_s

      if (parent_tag.empty?)
        # we are a parent, our basename is the key
        standard_items << item
        if progress_items[basename]
            progress_items[basename][:parent] = item # parent not yet set if progress items came first, set it now
        else
            progress_items[basename] = {parent:item, list:[]} # add root parent
        end
      else
        # we are a progress item, the parent_tag is the key
        if progress_items[parent_tag]
            progress_items[parent_tag][:list] << item # we already have the parent in our progress_items
        else
            progress_items[parent_tag] = {parent:nil, list:[item]} # parent will be set whenever we get to it in line 207 above
        end
      end
    end
    
    # Now enumerate through each item, using each_cons on a synthetic array so that:
    # for the first item, prev_item is the last item
    # for the last item, next_item is the first
    # otherwise what you would expect
    [standard_items.last, *standard_items, standard_items.first].each_cons(3) do |prev_item, item, next_item|
      image_name = item[:image].to_s
      if image_name.empty?
        puts "No image specified for #{item[:title]}" # error in spreadsheet
        next
      end
      basename = item[:basename]
      url = "#{category.to_s}/#{album_escaped}/#{basename}.html".downcase
      puts "image.html for #{url}" if print_paths
      proxy(
        url,
        '/image.html',
        locals: {
          category: category,
          album: album,
          album_escaped: item[:album_escaped],
          item: item,
          prev_item: prev_item,
          next_item: next_item
        },
        :ignore => true
      )
    end
    
    # enumerate all progress items
    progress_items.each do |parent_tag, parent_and_list|
        parent_item = parent_and_list[:parent]
        progress_list = parent_and_list[:list]

        unless parent_item
            puts "No parent photo for #{parent_tag}, skipping"
            next
        end
        if progress_list.empty?
          puts "No progress items for #{parent_tag}, skipping" if show_no_progress
          next
        end
        
        # first do index
        puts "Progress: #{category.to_s}/#{album_escaped}/#{parent_tag}/progress.html".downcase if print_paths
        proxy(
          "#{category.to_s}/#{album_escaped}/#{parent_tag}/progress.html".downcase,
          '/album.html',
          locals: {
            category: category,
            album: album,
            album_escaped: album_escaped,
            parent_item: parent_item,
            contents: progress_list
          },
          :ignore => true
        )
        
        # now do each item
        [progress_list.last, *progress_list, progress_list.first].each_cons(3) do |prev_item, item, next_item|
          image_name = item[:image].to_s
          if image_name.empty?
            puts "No image specified for #{item[:title]}" # error in spreadsheet
            next
          end
          basename = item[:basename]
          url = "#{category.to_s}/#{album_escaped}/#{parent_tag}/#{basename}.html".downcase
          puts "Progress image.html for #{url}" if print_paths
          proxy(
            url,
            '/image.html',
            locals: {
              category: category,
              album: album,
              album_escaped: item[:album_escaped],
              parent_item: parent_item,
              item: item,
              prev_item: prev_item,
              next_item: next_item
            },
            :ignore => true
          )
        end 
    end
  end
end

# Helpers
# Methods defined in the helpers block are available in templates
# https://middlemanapp.com/basics/helper-methods/

helpers do
  def img_path(item)
    # item is from csv file and has:
    #  - category ("oil")
    #  - album ("Doorknockers")
    #  - image ("st_marks_lion_and_girl-1.tif")
    image_name = item[:image].to_s
    if (image_name.empty?)
      puts "Unable to get path for #{item[:title]}"
      return ""
    end
    small_image = item[:basename]
    extension = (image_name =~ /.*\.png$/) ? "png" : "jpg" # Keep pngs for transparency, otherwise, convert to jpg
    small_image += "_1080.#{extension}" # add suffix and extension
    if item[:parent].to_s.empty?
      path = "/images/#{item[:category]}/#{item[:album_escaped]}/#{small_image}".downcase
    else
      path = "/images/#{item[:category]}/#{item[:album_escaped]}/#{item[:parent]}/#{small_image}".downcase
    end
    path
  end
  
  def category_path(category)
    "/#{category}".downcase
  end
  
  def album_path(item)
    "/#{item[:category]}/#{item[:album_escaped]}".downcase
  end
  
  def item_path(item)
    return "" unless item
    image_name = item[:image].to_s
    image_name = "unknown" if image_name.empty?
    if item[:parent].to_s.empty?
      path = "/#{item[:category]}/#{item[:album_escaped]}/#{item[:basename]}.html".downcase
    else
      path = "/#{item[:category]}/#{item[:album_escaped]}/#{item[:parent]}/#{item[:basename]}.html".downcase
    end
    path
  end
  
  def progress_path(item)
    image_name = item[:image].to_s
    image_name = "unknown" if image_name.empty?
    "/#{item[:category]}/#{item[:album_escaped]}/#{item[:basename]}/progress.html".downcase
  end
  
  def link_to_if(name, link)
    if link
      link_to(name, link)
    else
      name # alternative is to do a link with <a name="#">name</a>
    end
  end
  
  # from https://forum.middlemanapp.com/t/getting-the-current-route-or-uri/994/3
  # adds 'active' to class for current URL in nav links
  # usage:
  #   <%= nav_link "My page", "/about/page", class: "optional classes" %>
  def nav_link(title, path, options = {})
    options[:class] = (options[:class] or '').split(' ')
    options[:class] << 'active' if current_page?(path)
    options[:class] = options[:class].join(' ')

    link = link_to(title, path, options)
    # content_tag(:li, link, options)
    link
  end
  
  def current_page?(path)
    current_page.url.chomp('/') == path.chomp('/')
  end
end

# Build-specific configuration
# https://middlemanapp.com/advanced/configuration/#environment-specific-settings

# configure :build do
#   activate :minify_css
#   activate :minify_javascript
# end

require 'credentials.rb'

activate :deploy do |deploy|
  deploy.build_before = true # default: false
  deploy.deploy_method   = :ftp
  deploy.host            = Credentials::HOST
  deploy.path            = Credentials::PATH
  deploy.user            = Credentials::USER
  deploy.password        = Credentials::PASSWORD
end
