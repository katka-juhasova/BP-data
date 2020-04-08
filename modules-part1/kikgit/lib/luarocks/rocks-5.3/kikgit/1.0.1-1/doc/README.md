# kikgit

Tired of writing git commands? Hell, me too.

## What is it?

It's just a small script with two commands: `push` and `release`. These can be shortened to `p` and `r`.
The idea is that to push some changes, you first have to add the files, create a commit, then push. `push` does that by just writing `kikgit push`. Why not an alias? Well, you can use options to change the remote, branch, set the commit message,  skip adding and committing... `kikgit` release does a bit more than that, it also creates a tag and pushes it, useful for releases.

## Usage

```
Usage: kikgit [-h] <command> ...

Git, but quicker

Options:
   -h, --help            Show this help message and exit.

Commands:
   push, p               Pushes a simple commmit to the remote
   release, r            Releases a new version to the remote

Homepage - https://github.com/daelvn/kikgit

----

Usage: kikgit push [-r <remote>] [-b <branch>] [-j] [-p] [-h]
       [-m [<message>]]

Pushes a simple commmit to the remote

Options:
         -r <remote>,    Remote to perform the push on (default: origin)
   --remote <remote>
         -b <branch>,    Branch to perform the push on (default: master)
   --branch <branch>
          -m [<message>],
   --message [<message>]
                         Optional commit message
   -j, --just-push       Just push
   -p, --pull            Pull before pushing
   -h, --help            Show this help message and exit.

----

Usage: kikgit release [-r <remote>] [-b <branch>] [-p] [-j] [-h] <tag>
       [-m [<message>]]

Releases a new version to the remote

Arguments:
   tag                   Tag to release the commits with

Options:
         -r <remote>,    Remote to perform the push on (default: origin)
   --remote <remote>
         -b <branch>,    Branch to perform the push on (default: master)
   --branch <branch>
          -m [<message>],
   --message [<message>]
                         Optional commit message
   -p, --pull            Pull before pushing
   -j, --just-release    Just tag and push
   -h, --help            Show this help message and exit.
```

## Maintainer

Dael \<daelvn@gmail.com\>

## License

This is released to the public domain, do what you want with it.
