ElsworthArtworks
================

The source code (built on [Middleman]) for building [elsworthartworks.com], a static portfolio website
for Suzy Elsworth Heithcock.

Portfolio site map
------------------

The Portfolio organizes images first by Category (Oil, Ceramics, etc.) and then
by Albums (Figure Drawings, Landscapes, etc.). You can also include a folder
next to the image with the same name (without the extension) that will show as
a "View Progress" link on the image page.

An example folder structure would look like:

- Originals
  - oil
    - landscapes
      - inside-the-cyprus-tree.jpg
      - inside-the-cyprus-tree (folder of progress images of 'inside-the-cyprus-tree')

> [!NOTE]
> Folders named 'support' and 'not_for_publication' are not included.

Each image is copied to the _source/images_ folder as a reduced version (a max
of 1080px on either side).

Adding meta information to each image page
-------------------------------

In addition to the name, each image page can have the following information:

- Date
- Media (e.g. "Oil on Round Maple")
- Dimensions
- Price (if for sale)

This information is contained in the _Portfolio_Catalog.csv_ spreadsheet.
Building will create a _new.csv_ file with any missing artwork. This can be
copied over to the _Portfolio_Catalog.csv_ file as a stub entry.

Building, testing and deploying the portfolio
---------------------------------------------

You need a command line terminal to build and deploy using Middleman. Open a
terminal window, `cd` to the portfolio folder, and type:

`> bundle exec middleman build`

Or alternately, you can add more information (date, medium, dimensions) by
editing the _Portfolio_Catalog.csv_ file.

Progress pictures
-----------------

If a folder with the same name is found, all images in that folder will be used
to create a "Progress" link on that image's page. Again, more information can
be added to the .csv file if desired.

About, Articles & Awards, Clients, Shows, Videos
------------------------------------------------

These pages came about through time. The text for these are all pulled out of
the _data/site_info.yaml_ file. This can be edited in any text editor. For any
sections you do not need or want, delete them from the __headers.erb_ file.

Testing
-------

`> bundle exec middleman server`

Deploying to the website
------------------------

In the terminal, cd to this folder and type:

`> bundle exec middleman deploy`

Using this repo for your own portfolio site
-------------------------------------------

You are welcome to use this to kickstart your own portfolio site! Here is the work you will need to do:

- Download this repo
- Install [Middleman]
- Create a _credentials.rb_ file in the root folder (in the same folder as _config.rb_)
- Paste in the following code, changing to use your credentials for your own ftp site  [^bunnynet]:
```
  module Credentials
    HOST = 'my.ftp-site.com'
    PATH = '/myusername'
    USER = 'myusername'
    PASSWORD = 'myReallySecurePassword'
  end
```
- Delete _Portfolio_Catalog.csv_
- [Build the site](#building-testing-and-deploying-the-portfolio) and rename the newly created _new.csv_ to _Portfolio_Catalog.csv_
- Edit [_Portfolio_Catalog.csv_](#adding-meta-information-to-each-image-page) if desired to add any meta information.
- Edit the [data/site_info.yaml](#about-articles--awards-clients-shows-videos) file to change the About Me and other non-image pages.
- [Deploy](#deploying-to-the-website)!

[^bunnynet]: I am currently using [bunnynet.com](https://bunny.net/). Middleman supports FTP/SFTP, rsync, and Git.
  See the [Middleman-deploy docs] for more details.


<!--- Link references --->

[Middleman]: https://middlemanapp.com (Middleman-a static site generator)
[Middleman-deploy docs]: https://github.com/karlfreeman/middleman-deploy
[elsworthartworks.com]: https://www.elsworthartworks.com
