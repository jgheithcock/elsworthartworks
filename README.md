ElsworthArtworks
================

The source code (built on [Middleman]) for building [elsworthartworks.com], a portfolio website
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
      - inside-the-cyprus-tree (a folder)

> [!NOTE]
> Folders named 'support' and 'not_for_publication' are not included.

Each image is copied to the _source/images_ folder as a reduced version (a max
of 1080px on either side).

Adding information to each page
-------------------------------

In addition to the name, each image page can have the following information:

- Date
- Media (e.g. "Oil on Round Maple")
- Dimensions
- Price (if for sale)

This information is contained in the Portfolio_Catalog.csv spreadsheet.
Building will create a _new.csv_ file with any missing artwork. This can be
copied over to the Portfolio_Catalog.csv file as a stub entry.

Building, testing and deploying the portfolio
---------------------------------------------

You need a command line terminal to build and deploy using Middleman. Open a
terminal window, `cd` to the portfolio folder, and type:

`> bundle exec middleman build`

Or alternately, you can add more information (date, medium, dimensions) by editing the Portfolio_Catalog.csv file.

Progress pictures
-----------------

If a folder with the same name is found, all images in that folder will be used to create a "Progress" link on that image's page. Again, more information can be added to the .csv file if desired.

Testing
-------

`> bundle exec middleman server`

Deploying to the website
------------------------

In the terminal, cd to this folder and type:

`> bundle exec middleman deploy`

<!--- Link references --->

[Middleman]: https://middlemanapp.com (Middleman-a static site generator)
[elsworthartworks.com]: https://www.elsworthartworks.com
