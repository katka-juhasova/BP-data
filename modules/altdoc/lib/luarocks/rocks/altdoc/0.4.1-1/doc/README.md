# altdoc

Language-agnostic documentation generator, because I dislike LDoc and Docco is just a bit too much.

It uses [MkDocs](https://github.com/mkdocs/mkdocs/) to generate the documentation pages and
[highlight](http://www.andre-simon.de/doku/highlight/en/highlight.php) to highlight source files.

## Installing

```
# pip install mkdocs
$ luarocks install altdoc
```

## Usage

```
Usage: altdoc [-d <docs_dir>] [-s <source_dir>] [-p <prefix>]
       [-a <anchor_prefix>] [--highlight-flags <highlight_flags>]
       [--highlight-extra <highlight_extra>] [-h] <path>
       [-E <exclude> [<exclude>] ...]

Language-agnostic documentation generator

Arguments:

   path                                 File or folder to extract documentation from

Options:

           -d <docs_dir>,               Destination directory for the documentation (default: docs/)
   --docs-dir <docs_dir>

             -s <source_dir>,           Destination directory for source files (default: docs/source/)
   --source-dir <source_dir>

         -p <prefix>,                   Comment prefix (default: -->)
   --prefix <prefix>

                -a <anchor_prefix>,     Comment prefix for linking to source (default: --#)
   --anchor-prefix <anchor_prefix>

          -E <exclude> [<exclude>] ..., Exclude a path from being scanned
   --exclude <exclude> [<exclude>] ...

   --highlight-flags <highlight_flags>  Flags to pass to highlight (default: -I -l --anchors -y L)

   --highlight-extra <highlight_extra>  Set extra flags to pass to highlight (default: )

   -h, --help                           Show this help message and exit.

Homepage - https://github.com/daelvn/altdoc
```

## Notes

Keep in mind, you are still required to provide a `mkdocs.yml`, this only extracts markdown comments, builds the page and
highlights the files.

## Source referencing

Using `--anchor-prefix`, you can place a comment in your code that will be represented in the site as a "source" link, and when clicked, it takes you to the line where the anchor was placed.
